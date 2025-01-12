import os

from conan import ConanFile
from conan.errors import ConanInvalidConfiguration
from conan.tools.build import check_min_cppstd
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.files import copy, get
from conan.tools.files import (
    apply_conandata_patches,
    export_conandata_patches
)

required_conan_version = ">=1.53.0"

class libbgcodeConan(ConanFile):
    name = "libbgcode"
    description = (
        "Prusa Block & Binary G-code reader/writer/converter"
    )
    license = ["GNU Affero General Public License v3.0"]
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://github.com/prusa3d/libbgcode"
    topics = ("gcode")

    package_type = "library"
    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False],
        "build_tests": [True, False],
        "build_cmd_tools": [True, False],
    }
    default_options = {
        "shared": False,
        "fPIC": True,
        "build_tests": False,
        "build_cmd_tools": False,
    }

    def export(self):
        self.output.warning("***** export.")

    def export_sources(self):
        export_conandata_patches(self)
        self.output.warning("***** export_sources.")

    def system_requirements(self):
        self.output.warning("***** system_requirements.")

    def requirements(self):
        self.requires("heatshrink/0.4.1")
        self.requires("zlib/[>=1.2.11 <2]")
        self.requires("boost/1.83.0")
        self.output.warning("***** requirements.")

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

        self.output.warning("***** config_options.")

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")
        self.settings.rm_safe("compiler.cppstd")
        self.settings.rm_safe("compiler.libcxx")

        self.output.warning("***** configure.")

    def layout(self):
        cmake_layout(self, src_folder="source_layout")
        self.output.warning("***** layout.")

    def source(self):
        get(self, **self.conan_data["sources"][self.version], strip_root=True)
        self.output.warning("***** source.")

    def generate(self):
        tc = CMakeToolchain(self)
        tc.variables["LibBGCode_BUILD_TESTS"] = self.options.build_tests
        tc.variables["LibBGCode_BUILD_CMD_TOOL"] = self.options.build_cmd_tools
        tc.generate()
        cd = CMakeDeps(self)
        cd.generate()
        self.output.warning("***** generate.")

    def build(self):
        apply_conandata_patches(self)
        cmake = CMake(self)
        cmake.configure()
        cmake.build()
        self.output.warning("***** build.")

    def package(self):
        cmake = CMake(self)
        cmake.install()
        self.output.warning("***** package.")

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "LibBGCode")
        self.cpp_info.set_property("cmake_target_name", "LibBGCode::LibBGCode")

        if self.settings.build_type == "Debug":
            lib_suffix = "d"
        else:
            lib_suffix = ""

        inc_find = [os.path.join("include", "LibBGCode"), "include"]
        rlibs = ["heatshrink::heatshrink", "zlib::zlib", "boost::boost"]

        self.cpp_info.components["bgcode_core"].libs = ["bgcode_core{}".format(lib_suffix)]
        self.cpp_info.components["bgcode_core"].includedirs = inc_find
        self.cpp_info.components["bgcode_core"].names["cmake_find_package"] = "bgcode_core"
        self.cpp_info.components["bgcode_core"].names["cmake_find_package_multi"] = "bgcode_core"
        self.cpp_info.components["bgcode_core"].set_property("cmake_target_name", "LibBGCode::bgcode_core")
        self.cpp_info.components["bgcode_core"].requires.extend(rlibs)

        self.cpp_info.components["bgcode_binarize"].libs = ["bgcode_binarize{}".format(lib_suffix)]
        self.cpp_info.components["bgcode_binarize"].includedirs = inc_find
        self.cpp_info.components["bgcode_binarize"].names["cmake_find_package"] = "bgcode_binarize"
        self.cpp_info.components["bgcode_binarize"].names["cmake_find_package_multi"] = "bgcode_binarize"
        self.cpp_info.components["bgcode_binarize"].set_property("cmake_target_name", "LibBGCode::bgcode_binarize")
        self.cpp_info.components["bgcode_binarize"].requires.extend(rlibs)

        self.cpp_info.components["bgcode_convert"].libs = ["bgcode_convert{}".format(lib_suffix)]
        self.cpp_info.components["bgcode_convert"].includedirs = inc_find
        self.cpp_info.components["bgcode_convert"].names["cmake_find_package"] = "bgcode_convert"
        self.cpp_info.components["bgcode_convert"].names["cmake_find_package_multi"] = "bgcode_convert"
        self.cpp_info.components["bgcode_convert"].set_property("cmake_target_name", "LibBGCode::bgcode_convert")
        self.cpp_info.components["bgcode_convert"].requires.extend(rlibs)
        self.output.warning("***** package_info.")
