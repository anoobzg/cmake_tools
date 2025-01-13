from conan import ConanFile
from conan.tools.cmake import CMake, CMakeToolchain, CMakeDeps, cmake_layout
from conan.tools.files import copy, get
from conan.tools.layout import basic_layout
import os

required_conan_version = ">=1.50.0"


class NanosvgConan(ConanFile):
    name = "nanosvg"
    description = "NanoSVG is a simple stupid single-header-file SVG parser."
    license = "Zlib"
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://github.com/memononen/nanosvg"
    topics = ("nanosvg", "svg", "parser", "header-only")
    package_type = "header-library"
    settings = "os", "arch", "compiler", "build_type"
    no_copy_source = True

    def layout(self):
        basic_layout(self, src_folder="src")

    def source(self):
        get(self, **self.conan_data["sources"][self.version], strip_root=True)

    def generate(self):
        tc = CMakeToolchain(self)
        tc.generate()
        cd = CMakeDeps(self)
        cd.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE.txt", src=self.source_folder, dst=os.path.join(self.package_folder, "licenses"))
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.includedirs.append(os.path.join("include", "nanosvg"))
        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []
        if self.settings.os in ["Linux", "FreeBSD"]:
            self.cpp_info.system_libs.append("m")

        self.cpp_info.set_property("cmake_file_name", "nanosvg")
        self.cpp_info.set_property("cmake_target_name", "nanosvg::nanosvg")

        self.cpp_info.components["svg"].libs = ["nanosvg"]
        self.cpp_info.components["svg"].includedirs = self.cpp_info.includedirs
        self.cpp_info.components["svg"].names["cmake_find_package"] = "svg"
        self.cpp_info.components["svg"].names["cmake_find_package_multi"] = "svg"
        self.cpp_info.components["svg"].set_property("cmake_target_name", "nanosvg::svg")

        self.cpp_info.components["raster"].libs = ["nanosvgraster"]
        self.cpp_info.components["raster"].includedirs = self.cpp_info.includedirs
        self.cpp_info.components["raster"].names["cmake_find_package"] = "raster"
        self.cpp_info.components["raster"].names["cmake_find_package_multi"] = "raster"
        self.cpp_info.components["raster"].set_property("cmake_target_name", "nanosvg::raster")       
