cmake_minimum_required(VERSION 3.15)
project(PackageTest CXX)

find_package(LibBGCode REQUIRED CONFIG)

add_executable(example example.cpp)
target_link_libraries(example LibBGCode::LibBGCode)
set_property(TARGET example PROPERTY CXX_STANDARD 17)
