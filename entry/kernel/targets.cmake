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
										INTERFACE ${_ILIBS}
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

function(__redirect_plugin_target_output target) 
    set_target_properties(${target} PROPERTIES
                        LIBRARY_OUTPUT_DIRECTORY_DEBUG "${LIB_OUTPUT_DIR}/Debug/plugins/${target}"
                        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${LIB_OUTPUT_DIR}/Debug/plugins/${target}"
                        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${BIN_OUTPUT_DIR}/Debug/plugins/${target}"
                        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${LIB_OUTPUT_DIR}/Release/plugins/${target}"
                        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${LIB_OUTPUT_DIR}/Release/plugins/${target}"
                        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${BIN_OUTPUT_DIR}/Release/plugins/${target}"
                        )
endfunction()

function(__redirect_pyd_output target) 
    set_target_properties(${target} PROPERTIES
                        LIBRARY_OUTPUT_DIRECTORY_DEBUG "${BIN_OUTPUT_DIR}/Debug/"
                        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${BIN_OUTPUT_DIR}/Debug/"
                        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${BIN_OUTPUT_DIR}/Debug/"
                        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${BIN_OUTPUT_DIR}/Release/"
                        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${BIN_OUTPUT_DIR}/Release/"
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

macro(__deploy_target target type)
    cmake_parse_arguments(target "OPENMP;DEPLOYQT;MAC_DEPLOYQT" ""
        "FOLDER;MAC_ICON;MAC_OUTPUT_NAME;MAC_GUI_IDENTIFIER;QML_PLUGINS" ${ARGN})
    
    if(CC_BC_MAC)
        if(target_MAC_ICON)
            set_source_files_properties(${target_MAC_ICON} PROPERTIES
                MACOSX_PACKAGE_LOCATION "Resources")
            list(APPEND ExtraSrc ${target_MAC_ICON})
        endif()
    endif()
        
    if(CC_BC_MAC)			
        set_target_properties(${target} PROPERTIES
            MACOSX_BUNDLE TRUE
        )
        if(target_MAC_OUTPUT_NAME)
            message(STATUS "${target} set mac properties OUTPUT_NAME ${target_MAC_OUTPUT_NAME}")
            set_target_properties(${target} PROPERTIES
                    OUTPUT_NAME ${target_MAC_OUTPUT_NAME}
            )
        endif()
        if(target_MAC_GUI_IDENTIFIER)
            message(STATUS "${target} set mac properties MACOSX_BUNDLE_GUI_IDENTIFIER ${target_MAC_GUI_IDENTIFIER}")
            set_target_properties(${target} PROPERTIES
                MACOSX_BUNDLE_GUI_IDENTIFIER ${target_MAC_GUI_IDENTIFIER}
            )
        endif()
        if(target_DEPLOYQT AND TARGET Qt${QT_VERSION_MAJOR}::Core)
            if(${type} STREQUAL "exe")
                message(STATUS "Mac ${target} deploy qt.")
                __mac_deploy_target_qt(${target})
            else()
                message(STATUS "Mac not support depoly qt except bundle.")
            endif()
        endif()
    endif()
    if(CC_BC_LINUX)
        if(target_DEPLOYQT AND TARGET Qt${QT_VERSION_MAJOR}::Core)
            if(${type} STREQUAL "exe")
                #message(STATUS "Linux ${target} deploy qt.")
                #__linux_deploy_target_qt(${target})
            else()
                message(STATUS "Linux not support depoly qt except bundle.")
            endif()
        endif()			
    endif()
    if(CC_BC_WIN)
        if(target_DEPLOYQT AND TARGET Qt${QT_VERSION_MAJOR}::Core)
            if(${type} STREQUAL "exe" OR ${type} STREQUAL "winexe")
                message(STATUS "win ${target} deploy qt.")
                __deploy_qt_target(${target})
            else()
                message(STATUS "win not support depoly qt except bundle.")
            endif()
        endif()
    endif()
    if(target_QML_PLUGINS)
        foreach(plugin ${target_QML_PLUGINS})
            set(targetName ${CMAKE_SHARED_LIBRARY_PREFIX}${plugin}${CMAKE_SHARED_LIBRARY_SUFFIX})
            get_target_property(DIR_NAME ${plugin} QML_PLUGIN_DIR_NAME)
            message(STATUS "qml plugin ${plugin} : ${DIR_NAME}")
            if(EXISTS ${DIR_NAME})
                if(CC_BC_WIN)
                    add_custom_command(TARGET ${target} POST_BUILD
                            COMMAND ${CMAKE_COMMAND} -E make_directory "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${plugin}/"
                            COMMAND ${CMAKE_COMMAND} -E copy ${DIR_NAME} "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${plugin}"
                            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${plugin}>/${targetName}" "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${plugin}"
                            )
                    install(DIRECTORY "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>/${plugin}" DESTINATION .)
                elseif(CC_BC_MAC)
                    add_custom_command(TARGET ${target} POST_BUILD
                            COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${target}>/../Resources/qml/${plugin}/"
                            COMMAND ${CMAKE_COMMAND} -E copy ${DIR_NAME} "$<TARGET_FILE_DIR:${target}>/../Resources/qml/${plugin}/"
                            COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${plugin}>/${targetName}" "$<TARGET_FILE_DIR:${target}>/../Resources/qml/${plugin}/"
                            )
                    if(CMAKE_BUILD_TYPE MATCHES "Release")
                        install(CODE "execute_process(COMMAND codesign --force --options=runtime -s \"${OSX_CODESIGN_IDENTITY}\"  	\"\${CMAKE_INSTALL_PREFIX}/${BUNDLE_NAME}.app/Contents/Resources/qml/${plugin}/${targetName}\")")
                    endif()
                elseif(CC_BC_LINUX)
                        #add_custom_command(TARGET ${target} POST_BUILD
                                        #                  COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${target}>/lib/${plugin}/"
                                        #                  COMMAND ${CMAKE_COMMAND} -E copy ${DIR_NAME} "$<TARGET_FILE_DIR:${target}>/lib/${plugin}/"
                                        #                 COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE_DIR:${plugin}>/${targetName}" "$<TARGET_FILE_DIR:${target}>/lib/${plugin}/"
                                        #                 )

                endif()
            else()
                message(STATUS "QML target ${plugin} not exist.")
            endif()
        endforeach()
    endif()
endmacro()

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
        # __fatal_message("SRCS is empty")
	endif()
	
	if(NOT INCS)
		set(INCS ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})
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
    if(NOT LIBS)
        set(LIBS)
    endif()
	
	string(TOUPPER ${target} UpperName)
			
	if(${UpperName}_STATIC)
		list(APPEND INTERFACE_DEFS USE_${UpperName}_STATIC)
		list(APPEND DEFS ${UpperName}_STATIC)
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
                                ${ARGN}
                                )
endmacro()

function(__init_target_extra target_name)
	cmake_parse_arguments(target "" ""
		"STANDARD;RUNTIME" ${ARGN})
    set(standard ${MAXIMUM_CXX_STANDARD})
	if (${target_STANDARD} STREQUAL cxx_std_14 OR ${target_STANDARD} STREQUAL cxx_std_11 OR ${target_STANDARD} STREQUAL cxx_std_17)
		set(standard ${entry})
	endif()

    target_compile_features(${target_name} PRIVATE ${standard})

    set_target_properties(${target_name} PROPERTIES
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_WEAK YES
        XCODE_ATTRIBUTE_GCC_INLINES_ARE_PRIVATE_EXTERN YES
        XCODE_ATTRIBUTE_GCC_SYMBOLS_PRIVATE_EXTERN YES
    )

	if(target_RUNTIME)
		# MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"		
		set_property(TARGET ${target_name} PROPERTY MSVC_RUNTIME_LIBRARY ${target_RUNTIME})
	endif()
endfunction()

function(__nice_target_sources target_name src_loc)
    set(writing_now "")
    set(private_sources "")
    set(public_sources "")
    set(interface_sources "")
    set(not_win_sources "")
    set(not_mac_sources "")
    set(not_linux_sources "")
    foreach (entry ${ARGN})
        if (${entry} STREQUAL "PRIVATE" OR ${entry} STREQUAL "PUBLIC" OR ${entry} STREQUAL "INTERFACE")
            set(writing_now ${entry})
        else()
            set(full_name ${src_loc}/${entry})
            if (${entry} MATCHES "(^|/)win/" OR ${entry} MATCHES "(^|/)winrc/" OR ${entry} MATCHES "(^|/)windows/" OR ${entry} MATCHES "[_\\/]win\\.")
                list(APPEND not_mac_sources ${full_name})
                list(APPEND not_linux_sources ${full_name})
            elseif (${entry} MATCHES "(^|/)mac/" OR ${entry} MATCHES "(^|/)darwin/" OR ${entry} MATCHES "(^|/)osx/" OR ${entry} MATCHES "[_\\/]mac\\." OR ${entry} MATCHES "[_\\/]darwin\\." OR ${entry} MATCHES "[_\\/]osx\\.")
                list(APPEND not_win_sources ${full_name})
                list(APPEND not_linux_sources ${full_name})
            elseif (${entry} MATCHES "(^|/)linux/" OR ${entry} MATCHES "[_\\/]linux\\.")
                list(APPEND not_win_sources ${full_name})
                list(APPEND not_mac_sources ${full_name})
            elseif (${entry} MATCHES "(^|/)posix/" OR ${entry} MATCHES "[_\\/]posix\\.")
                list(APPEND not_win_sources ${full_name})
            endif()
            if ("${writing_now}" STREQUAL "PRIVATE")
                list(APPEND private_sources ${full_name})
            elseif ("${writing_now}" STREQUAL "PUBLIC")
                list(APPEND public_sources ${full_name})
            elseif ("${writing_now}" STREQUAL "INTERFACE")
                list(APPEND interface_sources ${full_name})
            else()
                message(FATAL_ERROR "Unknown sources scope for target ${target_name}")
            endif()
            if (${src_loc} MATCHES "/Resources$")
                source_group(TREE ${src_loc} PREFIX Resources FILES ${full_name})
            else()
                source_group(TREE ${src_loc} PREFIX Sources FILES ${full_name})
            endif()
        endif()
    endforeach()

    if (NOT "${public_sources}" STREQUAL "")
        target_sources(${target_name} PUBLIC ${public_sources})
    endif()
    if (NOT "${private_sources}" STREQUAL "")
        target_sources(${target_name} PRIVATE ${private_sources})
    endif()
    if (NOT "${interface_sources}" STREQUAL "")
        target_sources(${target_name} INTERFACE ${interface_sources})
    endif()
    if (WIN32)
        set_source_files_properties(${not_win_sources} PROPERTIES HEADER_FILE_ONLY TRUE)
        set_source_files_properties(${not_win_sources} PROPERTIES SKIP_AUTOGEN TRUE)
    elseif (APPLE)
        set_source_files_properties(${not_mac_sources} PROPERTIES HEADER_FILE_ONLY TRUE)
        set_source_files_properties(${not_mac_sources} PROPERTIES SKIP_AUTOGEN TRUE)
    elseif (LINUX)
        set_source_files_properties(${not_linux_sources} PROPERTIES HEADER_FILE_ONLY TRUE)
        set_source_files_properties(${not_linux_sources} PROPERTIES SKIP_AUTOGEN TRUE)
    endif()
endfunction()

function(__remove_target_sources target_name src_loc)
    set(sources "")
    foreach (entry ${ARGN})
        set(full_name ${src_loc}/${entry})
        list(APPEND sources ${full_name})
    endforeach()

    set_source_files_properties(${sources} PROPERTIES HEADER_FILE_ONLY TRUE)
    set_source_files_properties(${sources} PROPERTIES SKIP_AUTOGEN TRUE)
endfunction()

function(__enable_target_openmp target_name)
    if(NOT TARGET external_openmp)
        add_library(external_openmp INTERFACE)

        find_package(OpenMP REQUIRED)
        target_link_libraries(external_openmp INTERFACE OpenMP::OpenMP_CXX)
    endif()

    target_link_libraries(${target_name} PRIVATE external_openmp)
endfunction()

macro(__wrapper_external_target target_name)
    cmake_parse_arguments(target "" "" "LIB" ${ARGN})
    set(build_external_name "${target_name}")

    if(NOT TARGET ${build_external_name})
        add_library(${build_external_name} INTERFACE IMPORTED GLOBAL)
        add_library(${build_external_name}::${build_external_name} ALIAS ${build_external_name})

        if(target_LIB)
            target_link_libraries(${build_external_name} INTERFACE ${target_LIB})
        endif()
    endif()
endmacro()

macro(__copy_targets_runtime)	
    cmake_parse_arguments(target "" "" "TARGET" ${ARGN})

    if(NOT TARGET __auto_copy_runtime)
        add_custom_target(__auto_copy_runtime ALL COMMENT "copy runtime library.")
    endif()

    if(target_TARGET)
        foreach(target ${target_TARGET})
            get_target_property(IMPORT_LOC_DEBUG ${target} IMPORTED_LOCATION_DEBUG)
            get_target_property(IMPORT_LOC_RELEASE ${target} IMPORTED_LOCATION_RELEASE)

            # __normal_message("target imported location : debug ${IMPORT_LOC_DEBUG}, release ${IMPORT_LOC_RELEASE}")
            if(NOT EXISTS ${IMPORT_LOC_DEBUG})
                set(IMPORT_LOC_DEBUG ${IMPORT_LOC_RELEASE})
            endif()

            if(IMPORT_LOC_DEBUG)
                set(COPY_FILE ${IMPORT_LOC_DEBUG})
            endif()
            if(IMPORT_LOC_RELEASE)
                set(COPY_FILE ${IMPORT_LOC_RELEASE})
            endif()

            if(EXISTS ${COPY_FILE})
                add_custom_command(TARGET __auto_copy_runtime PRE_BUILD
                    COMMAND ${CMAKE_COMMAND} -E make_directory "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>"
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different  
                        "${COPY_FILE}"
                        "${__BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>"
                    )
            endif()
	    endforeach()
    endif()
endmacro()


