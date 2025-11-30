from conan import ConanFile
from conan.tools.files import get, replace_in_file, copy
from conan.tools.build import cross_building
from conan.tools.layout import basic_layout
from conan.errors import ConanInvalidConfiguration
from conan.tools.env import VirtualBuildEnv
from conan.tools.microsoft import VCVars, is_msvc
from conan.tools.gnu import AutotoolsToolchain, Autotools
from conan.tools.apple import is_apple_os
import os

required_conan_version = ">=1.51.3"

class GenieConan(ConanFile):
    name = "genie"
    license = "BSD-3-clause"
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://github.com/bkaradzic/GENie"
    description = "Project generator tool"
    topics = ("genie", "project", "generator", "build", "build-systems")
    settings = "os", "arch", "compiler", "build_type"

    @property
    def _settings_build(self):
        # TODO: Remove for Conan v2
        return getattr(self, "settings_build", self.settings)

    def layout(self):
        basic_layout(self, src_folder="src")

    def package_id(self):
        del self.info.settings.compiler

    def validate(self):
        if hasattr(self, "settings_build") and cross_building(self):
            raise ConanInvalidConfiguration("Cross building is not yet supported. Contributions are welcome")

    def build_requirements(self):
        if self._settings_build.os == "Windows":
            self.win_bash = True
            if not self.conf.get("tools.microsoft.bash:path", default=False, check_type=str):
                self.tool_requires("msys2/cci.latest")
        if is_msvc(self):
            self.tool_requires("cccl/1.3")

    def source(self):
        get(self, **self.conan_data["sources"][self.version], destination=self.source_folder, strip_root=True)

    @property
    def _os(self):
        if is_apple_os(self):
            return "darwin"
        return {
            "Windows": "windows",
            "Linux": "linux",
            "FreeBSD": "bsd",
        }[str(self.settings.os)]

    def _patch_compiler(self, cc, cxx):
        makefile = os.path.join(self.source_folder, "build", f"gmake.{self._os}", "genie.make")
        
        if not os.path.exists(makefile):
            # Makefile might not exist yet, try to find it in alternative location
            alt_makefile = os.path.join(self.source_folder, "build", "gmake.windows", "genie.make")
            if os.path.exists(alt_makefile):
                makefile = alt_makefile
        
        if not os.path.exists(makefile):
            self.output.warn(f"Makefile not found at {makefile}, skipping compiler patch")
            return
        
        # Patch compiler settings
        try:
            replace_in_file(self, makefile, "CC  = gcc", f"CC = {cc}" if cc else "")
        except Exception:
            pass  # Pattern might not exist, that's okay
        
        try:
            replace_in_file(self, makefile, "CXX = g++", f"CXX = {cxx}" if cxx else "")
        except Exception:
            pass  # Pattern might not exist, that's okay
        
        # Fix linker command to avoid nologo.obj error on Windows with MSVC
        if is_msvc(self) and self._os == "windows":
            # Try different LINK variable formats
            link_patterns = [
                ("LINK =", "LINK = link /nologo"),
                ("LINK=", "LINK=link /nologo"),
                ("LINK := ", "LINK := link /nologo"),
                ("LINK:=", "LINK:=link /nologo"),
                ("LINK ?= ", "LINK ?= link /nologo"),
                ("LINK?=", "LINK?=link /nologo"),
            ]
            
            for pattern, replacement in link_patterns:
                try:
                    replace_in_file(self, makefile, pattern, replacement)
                    break  # Successfully replaced, no need to try others
                except Exception:
                    continue  # Try next pattern
            
            # Also fix any existing -nologo flags in the file
            nologo_patterns = [
                (" -nologo ", " /nologo "),
                ("-nologo ", "/nologo "),
                (" -nologo", " /nologo"),
                ("-nologo", "/nologo"),
            ]
            
            for pattern, replacement in nologo_patterns:
                try:
                    replace_in_file(self, makefile, pattern, replacement)
                except Exception:
                    pass  # Pattern might not exist, that's okay

    @property
    def _genie_config(self):
        return "debug" if self.settings.build_type == "Debug" else "release"

    def generate(self):
        vbe = VirtualBuildEnv(self)
        vbe.generate()
        if is_msvc(self):
            ms = VCVars(self)
            ms.generate()
        else:
            tc = AutotoolsToolchain(self)
            tc.generate()

    def build(self):
        if is_msvc(self):
            self._patch_compiler("cccl", "cccl")
            self.run("make", cwd=self.source_folder)
        else:
            self._patch_compiler("", "")

            autotools = Autotools(self)
            autotools.make(args=[f"-C {self.source_folder}", f"OS={self._os}", f"config={self._genie_config}"])

    def package(self):
        copy(self, pattern="LICENSE", src=self.source_folder, dst=os.path.join(self.package_folder, "licenses"))
        bin_ext = ".exe" if self.settings.os == "Windows" else ""
        copy(self, pattern=f"genie{bin_ext}", src=os.path.join(self.source_folder, "bin", self._os), dst=os.path.join(self.package_folder, "bin"))
        if self.settings.build_type == "Debug":
            copy(self, pattern="*.lua", src=os.path.join(self.source_folder, "src"), dst=os.path.join(self.package_folder,"res"))

    def package_info(self):
        self.cpp_info.libdirs = []
        self.cpp_info.includedirs = []
        
        #TODO remove for conan v2
        bindir = os.path.join(self.package_folder, "bin")
        self.output.info(f"Appending PATH environment variable: {bindir}")
        self.env_info.PATH.append(bindir)

        if self.settings.build_type == "Debug":
            resdir = os.path.join(self.package_folder, "res")
            self.output.info(f"Appending PREMAKE_PATH environment variable: {resdir}")
            self.env_info.PREMAKE_PATH.append(resdir)
