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

    configure_target(${target})
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