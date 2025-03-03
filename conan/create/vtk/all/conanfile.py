from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.scm import Git

required_conan_version = ">=1.53.0"

class VTKConan(ConanFile):
    name = "vtk"
    description = "The Visualization Toolkit (VTK) is open source software for manipulating and displaying scientific data"
    url = "https://github.com/conan-io/conan-center-index"
    homepage = "https://vtk.org/"
    license = "BSL-1.0"
    topics = ("libraries", "cpp")

    settings = "os", "arch", "compiler", "build_type"
    options = {
        "shared": [True, False],
        "fPIC": [True, False]
    }

    default_options = {
        "shared": True,
        "fPIC": True
    }

    def source(self):
        git = Git(self)
        git.clone(url="https://gitee.com/tjourney/VTK.git", target='.')
        git.checkout('8f2f116fd606b196edadce09fcb1d4f37558b105')

    def config_options(self):
        if self.settings.os == "Windows":
            self.options.rm_safe("fPIC")

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.builddirs = ["lib/cmake"]
        self.cpp_info.set_property("cmake_find_mode", "none")
