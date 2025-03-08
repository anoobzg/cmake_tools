# qt5
macro(__enable_qt5)
	if(NOT TARGET Qt5::Core)
		set(CMAKE_AUTOMOC ON)
		set(CMAKE_AUTORCC ON)
	
		find_package(Qt5 COMPONENTS Core Widgets Gui Xml Concurrent OpenGL Svg
                                    Quick Qml QuickWidgets 
                                    3DCore 3DRender 3DExtras 3DInput 3DLogic 3DQuick
                                    SerialPort Multimedia
                                    WebSockets
                                    LinguistTools
                                    )
		
		if(TARGET Qt5::Core)
			set(QT5_ENABLED 1)

			set(QT_VERSION ${Qt5_VERSION})
			set(QT_VERSION_MAJOR 5)

			add_library(external_qt INTERFACE IMPORTED GLOBAL)
			add_library(external_qt::external_qt ALIAS external_qt)
		
			set(libs Qt5::Core Qt5::Gui Qt5::Widgets Qt5::Network Qt5::Svg Qt5::OpenGL Qt5::OpenGLWidgets)
			target_link_libraries(external_qt INTERFACE ${libs})
		endif()
	endif()
endmacro()

macro(__wrapper_qt_resources sources)
	cmake_parse_arguments(resource "" "" "QTUI;QTQRC" ${ARGN})

	if(resource_QTUI AND TARGET Qt5::Core)
		set(UI_VAR)
		qt5_wrap_ui(UI_VAR ${resource_QTUI})
		list(APPEND ${sources} ${UI_VAR})
		__normal_message("__wrapper_qt_resources wrap ui-> ${UI_VAR}")
	endif()

	if(resource_QTQRC AND TARGET Qt5::Core)
		set(QT_QRC)
		qt5_add_resources(QT_QRC ${resource_QTQRC})
		list(APPEND ${sources} ${QT_QRC})
		__normal_message("__wrapper_qt_resources wrap qrc-> ${QT_QRC}")
	endif()
endmacro()