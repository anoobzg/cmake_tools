include(${CMAKE_CURRENT_LIST_DIR}/qt5.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/qt6.cmake)

macro(__enable_qt qt_version)
    if (${qt_version} STREQUAL "6")
        __enable_qt6()
        if (NOT TARGET external_qt)
            __enable_qt5()
        endif()
    elseif (${qt_version} STREQUAL "5")
        __enable_qt5()
        if(NOT TARGET external_qt)
            __enable_qt6()
        endif()
    else()
        __error_message("Invalid Qt version: ${qt_version}")
    endif()

    __assert_target(external_qt)
    __normal_message("Qt version: ${QT_VERSION}")
endmacro(__enable_qt)

macro(__qt_target_resources target_name)
    cmake_parse_arguments(target "" ""
        "UI;QRC" ${ARGN})
    if(target_UI)
        if(TARGET Qt6::Core)
            qt6_wrap_ui(UI_VAR ${target_UI})
        endif()
        if(TARGET Qt5::Core)
            qt5_wrap_ui(UI_VAR ${target_UI})
        endif()
        target_sources(${target_name} PRIVATE ${UI_VAR})
    endif()
    if(target_QRC)
        if(TARGET Qt6::Core)
            qt6_add_resources(QRC_VAR ${target_QRC})
        endif()
        if(TARGET Qt5::Core)
            qt5_add_resources(QRC_VAR ${target_QRC})
        endif()
        target_sources(${target_name} PRIVATE ${QRC_VAR})
    endif()
endmacro()

function(__deploy_qt_target)
    cmake_parse_arguments(arg "" "TARGET" "" ${ARGN})
    if(NOT arg_TARGET)
        __error_message("__deploy_qt_target. No target specified")
    endif()

    if(TARGET Qt6::Core)
        install(SCRIPT ${__CMAKE_MODULE_PATH}/qt/deploy_conf.cmake)
        qt_generate_deploy_app_script(
            ${ARGN}
            OUTPUT_SCRIPT deploy_script
            NO_UNSUPPORTED_PLATFORM_ERROR
        )

        __normal_message("Deploy qt script: ${deploy_script}")
        install(SCRIPT ${deploy_script})
    elseif(TARGET Qt5::Core)
        get_target_property(QT_QMAKE_EXECUTABLE Qt5::qmake IMPORTED_LOCATION)
        get_filename_component(QT_BIN_DIR ${QT_QMAKE_EXECUTABLE} DIRECTORY)
        set(QT_ROOT_DIR "${QT_BIN_DIR}/..")

        if(CC_BC_MAC)
            set(MACDEPLOYQT "${QT_BIN_DIR}/macdeployqt")

            install(CODE "
                message(STATUS \"Running macdeployqt on installed $<TARGET_FILE_NAME:${arg_TARGET}> bundle...\")
                execute_process(
                    COMMAND \"${MACDEPLOYQT}\" \"$<TARGET_FILE_NAME:${arg_TARGET}>.app\"
                    -always-overwrite
                    -appstore-compliant
                    -verbose=1
                    -qmldir=${QML_ENTRY_DIR}
                    WORKING_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}\"
                    OUTPUT_VARIABLE   output
                )
                message(STATUS \"${MACDEPLOYQT} output: ${output}\")
            ")

            set(QT_PLUGINS_DIR "${QT_ROOT_DIR}/plugins")
            # install qt extra plugins
            set(extra_plugin_dirs
                                "renderers"
                                )
            foreach(plugin_dir IN LISTS extra_plugin_dirs)
                install(DIRECTORY "${QT_PLUGINS_DIR}/${plugin_dir}/"
                        DESTINATION "$<TARGET_FILE_NAME:${arg_TARGET}>.app/Contents/PlugIns/${plugin_dir}/"
                        FILES_MATCHING PATTERN "*.dylib")
            endforeach()

            install(
                FILES ${CMAKE_SOURCE_DIR}/cmake/ci/package/deployqt.sh
                    ${CMAKE_SOURCE_DIR}/cmake/ci/check_deps.sh
                DESTINATION .
                PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ 
            )

            install(CODE "
                execute_process(
                    COMMAND bash deployqt.sh \"$<TARGET_FILE_NAME:${arg_TARGET}>.app\"
                    WORKING_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}\"
                    RESULT_VARIABLE result
                )
                
                if(NOT result EQUAL 0)
                    message(FATAL_ERROR \"Failed to run deployqt.sh: \${result}\")
                endif()
                ")

        elseif(CC_BC_WIN)
            find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${QT_BIN_DIR}")
            if(WIN32 AND NOT WINDEPLOYQT_EXECUTABLE)
                message(FATAL_ERROR "windeployqt not found")
            endif()

            install(CODE "
                message(STATUS \"Running windeployqt on installed $<TARGET_FILE_NAME:${arg_TARGET}>...\")
                execute_process(
                    COMMAND \"${WINDEPLOYQT_EXECUTABLE}\" \"$<TARGET_FILE_NAME:${arg_TARGET}>\"
                    --verbose 0
                    --no-compiler-runtime
                    --angle
                    --qmldir ${QML_ENTRY_DIR}
                    --dir .
                    OUTPUT_VARIABLE   output
                    WORKING_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}\"
                )
                message(STATUS \"${WINDEPLOYQT_EXECUTABLE} output: ${output}\")
            ")

            # INSTALL(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/windeployqt/ DESTINATION .)
        else()
        endif()	
    endif()
endfunction()

macro(__build_qml_plugin target_name)
	if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/qmldir)
		message(FATAL_ERROR "${CMAKE_CURRENT_SOURCE_DIR}/qmldir must exist in a qml plugin")
	endif()
	set_target_properties(${target_name} PROPERTIES QML_PLUGIN_DIR_NAME ${CMAKE_CURRENT_SOURCE_DIR}/qmldir)
	
	# __configure_qml_plugin_target(${target_name})
endmacro()



