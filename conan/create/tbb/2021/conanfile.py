from conan import ConanFile
from conan.tools.files import copy, get, rmdir
from conan.tools.cmake import CMake, CMakeToolchain, cmake_layout
import os
import textwrap

required_conan_version = ">=1.43.0"


class TBBConan(ConanFile):
    deprecated = "onetbb"

    name = "tbb"
    license = "Apache-2.0"
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://github.com/oneapi-src/oneTBB"
    description = (
        "Intel Threading Building Blocks (Intel TBB) lets you easily write "
        "parallel C++ programs that take full advantage of multicore "
        "performance, that are portable and composable, and that have "
        "future-proof scalability"
    )
    topics = ("tbb", "threading", "parallelism", "tbbmalloc")

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "tbbmalloc": [True, False],
        "tbbproxy": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "tbbmalloc": True,
        "tbbproxy": False,
    }

    @property
    def _source_subfolder(self):
        return "source_subfolder"

    @property
    def _settings_build(self):
        return getattr(self, "settings_build", self.settings)

    @property
    def _is_msvc(self):
        return str(self.settings.compiler) in ["Visual Studio", "msvc"]

    @property
    def _is_clanglc(self):
        return self.settings.os == "Windows" and self.settings.compiler == "clang"

    @property
    def _base_compiler(self):
        base = self.settings.get_safe("compiler.base")
        if base:
            return self.settings.compiler.base
        return self.settings.compiler

    def config_options(self):
        print("****** debug config_options:")
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        print("****** debug configure:")
        if self.options.shared:
            del self.options.fPIC

    def validate(self):
        print("****** debug validate:")
        if self.settings.os == "Macos":
            if hasattr(self, "settings_build") and tools.cross_building(self):
                # See logs from https://github.com/conan-io/conan-center-index/pull/8454
                raise ConanInvalidConfiguration("Cross building on Macos is not yet supported. Contributions are welcome")
            if self.settings.compiler == "apple-clang" and tools.Version(self.settings.compiler.version) < "8.0":
                raise ConanInvalidConfiguration("%s %s couldn't be built by apple-clang < 8.0" % (self.name, self.version))
        if not self.options.shared:
            self.output.warning("Intel-TBB strongly discourages usage of static linkage")
        if self.options.tbbproxy and \
           (not self.options.shared or \
            not self.options.tbbmalloc):
            raise ConanInvalidConfiguration("tbbproxy needs tbbmaloc and shared options")

    def package_id(self):
        print("****** debug package_id:")
        del self.info.options.tbbmalloc
        del self.info.options.tbbproxy

    def build_requirements(self):
        print("****** debug build_requirements:")

    def source(self):
        print("****** debug source:")
        get(self, **self.conan_data["sources"][self.version],
                  strip_root=True, destination=self._source_subfolder)

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        print("****** debug build:")
        cmake = CMake(self)
        vars = {"TBB_TEST":"OFF"}
        cmake.configure(build_script_folder=self._source_subfolder, variables=vars)
        cmake.build()

    def package(self):
        print("****** debug package:")
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        print("****** debug package_info:")
        self.cpp_info.set_property("cmake_file_name", "TBB")

        suffix = "_debug" if self.settings.build_type == "Debug" else ""

        # tbb
        self.cpp_info.components["libtbb"].set_property("cmake_target_name", "TBB::tbb")
        self.cpp_info.components["libtbb"].libs = ["tbb{}".format(suffix)]
        if self.settings.os in ["Linux", "FreeBSD"]:
            self.cpp_info.components["libtbb"].system_libs = ["dl", "rt", "pthread"]

        # tbbmalloc
        if self.options.tbbmalloc:
            self.cpp_info.components["tbbmalloc"].set_property("cmake_target_name", "TBB::tbbmalloc")
            self.cpp_info.components["tbbmalloc"].libs = ["tbbmalloc{}".format(suffix)]
            if self.settings.os in ["Linux", "FreeBSD"]:
                self.cpp_info.components["tbbmalloc"].system_libs = ["dl", "pthread"]

            # tbbmalloc_proxy
            if self.options.tbbproxy:
                self.cpp_info.components["tbbmalloc_proxy"].set_property("cmake_target_name", "TBB::tbbmalloc_proxy")
                self.cpp_info.components["tbbmalloc_proxy"].libs = ["tbbmalloc_proxy{}".format(suffix)]
                self.cpp_info.components["tbbmalloc_proxy"].requires = ["tbbmalloc"]

        # TODO: to remove in conan v2 once cmake_find_package* generators removed
        self.cpp_info.names["cmake_find_package"] = "TBB"
        self.cpp_info.names["cmake_find_package_multi"] = "TBB"
        self.cpp_info.components["libtbb"].names["cmake_find_package"] = "tbb"
        self.cpp_info.components["libtbb"].names["cmake_find_package_multi"] = "tbb"
