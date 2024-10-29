from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.scm import Git

class Trimesh2Recipe(ConanFile):
    name = "openctm"
    
    # Optional metadata
    license = "<Put the package license here>"
    author = "<Put your name here> <And your email here>"
    url = "<Package recipe repository url here, for issues about the package>"
    description = "<Description of sdl package here>"
    topics = ("<Put some tag here>", "<here>", "<and here>")

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}

    def source(self):
        git = Git(self)
        git.clone(url="https://github.com/anoobzg/OpenCTM.git", target='.')
        git.checkout('4ffc7c2268fd02019401e6aa0674331a893af89e')

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
        def lib_name(name):
            if self.options.shared == False:
                return name + "static"
            return name
        self.cpp_info.builddirs = ["cmake"]
        if self.settings.os == "Windows" and not self.options.shared:
            self.cpp_info.components["openctm"].defines.append("OPENCTM_STATIC")
        self.cpp_info.components["openctm"].libs.append(lib_name("openctm"))


    
