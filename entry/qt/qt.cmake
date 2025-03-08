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

macro(__deploy_qt_target target_name)
    if(TARGET Qt6::Core)

        install(SCRIPT ${__CMAKE_MODULE_PATH}/qt/deploy_conf.cmake)
        qt_generate_deploy_app_script(
            TARGET ${target_name}
            OUTPUT_SCRIPT deploy_script
            NO_UNSUPPORTED_PLATFORM_ERROR
        )

        __normal_message("Deploy qt script: ${deploy_script}")
        install(SCRIPT ${deploy_script})
    elseif(TARGET Qt5::Core)
        include(${__CMAKE_MODULE_PATH}/qt/deploy_qt5.cmake)
        if(CC_BC_WIN)
            __windeployqt(${target_name})
        elseif(CC_BC_MAC)
            __macdeployqt(${target_name})
        elseif(CC_BC_LINX)
            __linuxdeployqt(${target_name})
        endif()
    endif()
endmacro()

macro(__build_qml_plugin target_name)
	if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/qmldir)
		message(FATAL_ERROR "${CMAKE_CURRENT_SOURCE_DIR}/qmldir must exist in a qml plugin")
	endif()
	set_target_properties(${target_name} PROPERTIES QML_PLUGIN_DIR_NAME ${CMAKE_CURRENT_SOURCE_DIR}/qmldir)
	
	# __configure_qml_plugin_target(${target_name})
endmacro()



