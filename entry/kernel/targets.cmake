set(USER_BINARY_DIR ${CMAKE_BINARY_DIR}/..)

set(BIN_OUTPUT_DIR "${USER_BINARY_DIR}/bin")
set(LIB_OUTPUT_DIR "${USER_BINARY_DIR}/lib")
set(LIB_DEBUG_DIR ${LIB_OUTPUT_DIR}/Debug/)
set(LIB_RELEASE_DIR ${LIB_OUTPUT_DIR}/Release/)

message(STATUS "bin : ${BIN_OUTPUT_DIR}")
message(STATUS "lib : ${LIB_OUTPUT_DIR}")

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# wrap cmake function 
# target_link_libraries
# target_include_directories
# target_compile_definitions
# INTERFACE_COMPILE_DEFINITIONS
# INTERFACE_INCLUDE_DIRECTORIES
# FOLDER
function(__modify_target target)  
	cmake_parse_arguments(target "" ""
		"INC;LIB;ILIB;DEF;INTERFACE;FOLDER;INTERFACE_DEF" ${ARGN})

    if(target_LIB OR target_ILIB)
        set(_ILIBS)
        set(_LIBS)
        if(target_LIB)
            set(_LIBS ${target_LIB})
        endif()
        if(target_ILIB)
            set(_ILIBS ${target_ILIB})
        endif()
        
        target_link_libraries(${target} PRIVATE ${_LIBS}
                                        PUBLIC ${_ILIBS}
                                        )
                                        
        message(STATUS "${target} -> public [${_ILIBS}] private [${_LIBS}]")
    endif()
    #incs
    if(target_INC)
        target_include_directories(${target} PRIVATE ${target_INC})	
    endif()
    #def
    if(target_DEF)
        target_compile_definitions(${target} PRIVATE ${target_DEF})	
    endif()
    if(target_INTERFACE_DEF)
        set_property(TARGET ${target} PROPERTY INTERFACE_COMPILE_DEFINITIONS ${target_INTERFACE_DEF})
    endif()
    if(target_INTERFACE)
        set_property(TARGET ${target} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${target_INTERFACE})
    endif()
    if(target_FOLDER)
        set_target_properties(${target} PROPERTIES FOLDER ${target_FOLDER})
    endif()

    __redirect_target_output(${target})

	get_property(MR_DYNAMIC GLOBAL PROPERTY MSVC_RUNTIME_DYNAMIC)
	if(MR_DYNAMIC)
		set_property(TARGET ${target} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	else()
		set_property(TARGET ${target} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
	endif()
endfunction()

# wrap cmake function 
# target output directory
function(__redirect_target_output target) 
    set_target_properties(${target} PROPERTIES
                        LIBRARY_OUTPUT_DIRECTORY_DEBUG "${LIB_OUTPUT_DIR}/Debug/"
                        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${LIB_OUTPUT_DIR}/Debug/"
                        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${BIN_OUTPUT_DIR}/Debug/"
                        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${LIB_OUTPUT_DIR}/Release/"
                        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${LIB_OUTPUT_DIR}/Release/"
                        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${BIN_OUTPUT_DIR}/Release/"
                        )
endfunction()

#port from ConfigureTargets.cmake
macro(__add_include_interface package)
	cmake_parse_arguments(package "" "" "INTERFACE;INTERFACE_DEF" ${ARGN})

	set(INCS ${CMAKE_CURRENT_SOURCE_DIR})
	if(package_INTERFACE)
		set(INCS ${package_INTERFACE})
	endif()
	
	if(NOT TARGET ${package})
		add_library(${package} INTERFACE)
		set_property(TARGET ${package} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${INCS})
		
		if(package_INTERFACE_DEF)
			set_property(TARGET ${package} PROPERTY INTERFACE_COMPILE_DEFINITIONS ${package_INTERFACE_DEF})
		endif()
	endif()
endmacro()

#only for exe obj and ..
function(__add_real_target target type)
	cmake_parse_arguments(target "" ""
		"SOURCE;INC;LIB;ILIB;DEF;DEP;INTERFACE" ${ARGN})
	if(target_SOURCE)
		if(${type} STREQUAL "exe")
			add_executable(${target} ${target_SOURCE})
		elseif(${type} STREQUAL "winexe")
			add_executable(${target} WIN32 ${target_SOURCE})
		elseif(${type} STREQUAL "bundle")
			add_executable(${target} MACOSX_BUNDLE ${target_SOURCE})
		elseif(${type} STREQUAL "dll")
            __fatal_message("__add_real_target not support dll anymore, use __add_common_library instead")
		elseif(${type} STREQUAL "lib")
            __fatal_message("__add_real_target not support lib anymore, use __add_common_library instead")
		elseif(${type} STREQUAL "obj")
			add_library(${target} OBJECT ${target_SOURCE})
		else()
            add_executable(${target} ${target_SOURCE})
		endif()
    else()
        __fatal_message("__add_real_target must provide SOURCE")
    endif()

	__modify_target(${target} ${ARGN})
endfunction()

#common entry for library(lib, dll)
#use ${UpperTarget}_STATIC 
macro(__add_common_library target)
	if(NOT INTERFACES)
		set(INTERFACES ${CMAKE_CURRENT_SOURCE_DIR})
		if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include")
			list(APPEND INTERFACES ${CMAKE_CURRENT_SOURCE_DIR}/include)
		endif()
	endif()
	
	if(NOT SRCS)
        __fatal_message("SRCS is empty")
	endif()
	
	if(NOT INCS)
		set(INCS ${CMAKE_CURRENT_SOURCE_DIR})
	endif()
	
	if(NOT DEFS)
		set(DEFS)
	endif()
	if(NOT INTERFACE_DEFS)
		set(INTERFACE_DEFS)
	endif()
	if(NOT ILIBS)
		set(ILIBS)
	endif()
	
	string(TOUPPER ${target} UpperName)
			
	if(${UpperName}_STATIC)
		list(APPEND INTERFACE_DEFS USE_${UpperName}_STATIC)
		add_library(${target} STATIC ${SRCS})
	else()
		list(APPEND DEFS ${UpperName}_DLL)
		list(APPEND INTERFACE_DEFS USE_${UpperName}_DLL)
		add_library(${target} SHARED ${SRCS})
	endif()

    __modify_target(${target} 	LIB ${LIBS}
                                ILIB ${ILIBS}
                                INC ${INCS}
                                DEF ${DEFS}
                                INTERFACE ${INTERFACES}
                                INTERFACE_DEF ${INTERFACE_DEFS}
                                )
endmacro()