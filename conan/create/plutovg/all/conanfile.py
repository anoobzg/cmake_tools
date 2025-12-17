from conan import ConanFile
from conan.tools.apple import fix_apple_shared_install_name
from conan.tools.env import VirtualBuildEnv
from conan.tools.files import apply_conandata_patches, copy, export_conandata_patches, get, rm, rmdir, rename
from conan.tools.gnu import PkgConfigDeps
from conan.tools.layout import basic_layout
from conan.tools.meson import Meson, MesonToolchain
from conan.tools.microsoft import is_msvc
import os

required_conan_version = ">=2.4"


class FixedMeson(Meson):
    """
    Custom Meson class that fixes the Windows prefix issue.
    Replaces the hardcoded --prefix=/ with a valid absolute path for Windows.
    """
    def configure(self, reconfigure=False):
        """
        Runs meson setup with correct prefix path instead of hardcoded --prefix=/
        Based on Conan's Meson.configure() but with Windows prefix fix.
        """
        if reconfigure:
            self._conanfile.output.warning("reconfigure param has been deprecated."
                                           " Removing in Conan 2.x.", warn_tag="deprecated")
        source_folder = self._conanfile.source_folder
        build_folder = self._conanfile.build_folder
        generators_folder = self._conanfile.generators_folder
        cross = os.path.join(generators_folder, MesonToolchain.cross_filename)
        native = os.path.join(generators_folder, MesonToolchain.native_filename)
        is_cross_build = os.path.exists(cross)
        machine_files = self._conanfile.conf.get("tools.meson.mesontoolchain:extra_machine_files",
                                                 default=[], check_type=list)
        cmd = "meson setup "
        if is_cross_build:
            machine_files.insert(0, cross)
            cmd += " ".join([f'--cross-file "{file}"' for file in machine_files])
        if os.path.exists(native):
            if not is_cross_build:  # machine files are only appended to the cross or the native one
                machine_files.insert(0, native)
                cmd += " ".join([f'--native-file "{file}"' for file in machine_files])
            else:  # extra native file for cross-building scenarios
                cmd += f' --native-file "{native}"'
        cmd += ' "{}" "{}"'.format(build_folder, source_folder)
        # Fix: Use a simple absolute path for Windows instead of hardcoded --prefix=/
        # We'll use --destdir in install() to control the actual installation location
        if self._conanfile.settings.os == "Windows":
            # Use a simple root path that Meson accepts on Windows
            prefix_path = "C:/"
        else:
            prefix_path = "/"
        cmd += f' --prefix="{prefix_path}"'
        self._conanfile.output.info("Meson configure cmd: {}".format(cmd))
        self._conanfile.run(cmd)
    
    def install(self):
        """
        Runs meson install with --destdir to install directly to package_folder.
        This avoids path duplication issues.
        """
        build_folder = self._conanfile.build_folder
        package_folder = self._conanfile.package_folder
        # Use --destdir to install directly to package_folder
        # Meson installs to destdir + prefix + relative_path
        # Since prefix is C:/ on Windows, we need destdir to be package_folder
        # This results in package_folder/C:/... which is wrong
        # 
        # Actually, we should set destdir such that destdir + prefix = package_folder
        # If prefix is C:/, we can't really do this...
        #
        # Better approach: reconfigure prefix to package_folder before install
        # Or use meson configure to change prefix, then install without destdir
        prefix_path = package_folder.replace("\\", "/")
        # Reconfigure prefix to package_folder
        self._conanfile.run(f'meson configure -Dprefix="{prefix_path}" "{build_folder}"')
        # Now install without destdir, files will go directly to prefix (package_folder)
        self._conanfile.run(f'meson install -C "{build_folder}"')

class PlutoVGConan(ConanFile):
    name = "plutovg"
    description = "Tiny 2D vector graphics library in C"
    license = "MIT",
    topics = ("vector", "graphics", )
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://github.com/sammycage/plutovg"
    package_type = "library"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
    }

    implements = ["auto_shared_fpic"]
    languages = "C"

    def export_sources(self):
        export_conandata_patches(self)

    def layout(self):
        basic_layout(self, src_folder="src")

    def build_requirements(self):
        self.tool_requires("meson/[>=1.2.3 <2]")
        if not self.conf.get("tools.gnu:pkg_config", default=False, check_type=str):
            self.tool_requires("pkgconf/[>=2.2 <3]")

    def source(self):
        get(self, **self.conan_data["sources"][self.version], strip_root=True)
        apply_conandata_patches(self)

    def generate(self):
        # Fix Windows prefix path issue: prefix must be an absolute path
        # Convert Windows path to forward slashes for Meson
        prefix_path = self.package_folder.replace("\\", "/")
        
        tc = MesonToolchain(self)
        # Set prefix before setting other options
        tc.prefix = prefix_path
        tc.project_options["examples"] = "disabled"
        tc.project_options["tests"] = "disabled"
        tc.generate()
        tc = PkgConfigDeps(self)
        tc.generate()

    def build(self):
        # Use FixedMeson instead of Meson to fix Windows prefix issue
        meson = FixedMeson(self)
        meson.configure()
        meson.build()

    def package(self):
        copy(self, "LICENSE", self.source_folder, os.path.join(self.package_folder, "licenses"))
        meson = FixedMeson(self)
        meson.install()

        # some files extensions and folders are not allowed. Please, read the FAQs to get informed.
        rmdir(self, os.path.join(self.package_folder, "lib", "pkgconfig"))
        rmdir(self, os.path.join(self.package_folder, "share"))
        rm(self, "*.pdb", os.path.join(self.package_folder, "lib"))
        rm(self, "*.pdb", os.path.join(self.package_folder, "bin"))

        fix_apple_shared_install_name(self)

        if is_msvc(self) and not self.options.shared:
            # Rename libplutovg.a to plutovg.lib for MSVC static library
            lib_a_path = os.path.join(self.package_folder, "lib", "libplutovg.a")
            lib_lib_path = os.path.join(self.package_folder, "lib", "plutovg.lib")
            # Only rename if the .a file exists
            if os.path.exists(lib_a_path):
                rename(self, lib_a_path, lib_lib_path)

    def package_info(self):
        self.cpp_info.libs = ["plutovg"]
        self.cpp_info.includedirs = ["include", os.path.join("include", "plutovg")]
        if self.settings.os in ("FreeBSD", "Linux"):
            self.cpp_info.system_libs = ["m"]
        if is_msvc(self) and not self.options.shared:
            self.cpp_info.defines.append("PLUTOVG_BUILD_STATIC")

