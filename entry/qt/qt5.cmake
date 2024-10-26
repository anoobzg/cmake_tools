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