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