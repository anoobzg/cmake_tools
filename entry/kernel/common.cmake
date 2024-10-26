######### platform
#Build Case Flag
#CC_BC_WIN   
#CC_BC_ANDROID
#CC_BC_MAC
#CC_BC_IOS
#CC_BC_GNU 
#CC_BC_EMCC

set(CC_BC_WIN 0)
set(CC_BC_ANDROID 0)
set(CC_BC_MAC 0)
set(CC_BC_IOS 0)
set(CC_BC_LINUX 0)
set(CC_BC_EMCC 0)

__normal_message("CMAKE_SYSTEM_NAME ---> ${CMAKE_SYSTEM_NAME}")

if(WIN32)
	set(CC_BC_WIN 1)
endif()

if(APPLE)
	set(CC_BC_MAC 1)
endif()

if(ANDROID)
	set(CC_BC_ANDROID 1)
endif()

if(UNIX AND NOT APPLE)
	set(CC_BC_LINUX 1)
endif()

if(CC_BC_WIN)
	__normal_message("CC Build Case [ WIN ]")
	add_definitions(-DCC_SYSTEM_WIN)
endif()
if(CC_BC_ANDROID)
	__normal_message("CC Build Case [ ANDROID ]")
	add_definitions(-DCC_SYSTEM_ANDROID)
endif()
if(CC_BC_MAC)
	__normal_message("CC Build Case [ MAC ]")
	add_definitions(-DCC_SYSTEM_MAC)
endif()
if(CC_BC_IOS)
	__normal_message("CC Build Case [ IOS ]")
	add_definitions(-DCC_SYSTEM_IOS)
endif()
if(CC_BC_LINUX)
	__normal_message("CC Build Case [ LINUX ]")
	add_definitions(-DCC_SYSTEM_LINUX)
endif()
if(CC_BC_EMCC)
	__normal_message("CC Build Case [ EMCC ]")
	add_definitions(-DCC_SYSTEM_EMCC)
endif()
######### platform end

if(NOT WIN32)
	if(NOT CMAKE_BUILD_TYPE)
		set(CMAKE_BUILD_TYPE "Release")
		message(STATUS "Default Build Type ${CMAKE_BUILD_TYPE}")
	endif()
	
	if(CMAKE_BUILD_TYPE STREQUAL "Release")
		add_definitions(-DNDEBUG)
	else()
		add_definitions(-DDEBUG)
		add_definitions(-D_DEBUG)
	endif()

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif()

add_definitions(-D_CRT_SECURE_NO_WARNINGS)

if(WIN32)
	set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
		$<$<CONFIG:Release>:NDEBUG>)
	set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
		$<$<CONFIG:Debug>:CXX_CHECK_MEMORY_LEAKS>)
	if(NOT DISABLE_DEBUG_DEF)
		set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
			$<$<CONFIG:Debug>:_DEBUG>)
		set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS
			$<$<CONFIG:Debug>:DEBUG>)
	endif()
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/cmake)
include_directories(${CMAKE_BINARY_DIR})


