macro(__enable_qt6)
    find_package(Qt6 COMPONENTS Core REQUIRED)
    if (Qt6_FOUND)
        set(QT_VERSION ${Qt6_VERSION})
        set(QT_VERSION_MAJOR 6)

		set(CMAKE_AUTOMOC ON)
		set(CMAKE_AUTORCC ON)
        
        find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Core Gui Widgets Network Svg Concurrent REQUIRED)
        find_package(Qt${QT_VERSION_MAJOR} COMPONENTS OpenGL OpenGLWidgets REQUIRED)
        find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Charts SerialPort REQUIRED)

        set(libs Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Network Qt6::Svg Qt6::Concurrent Qt6::OpenGL Qt6::OpenGLWidgets Qt6::Charts Qt6::SerialPort)

        add_library(external_qt INTERFACE IMPORTED GLOBAL)
        add_library(external_qt::external_qt ALIAS external_qt)
    
        target_link_libraries(external_qt INTERFACE ${libs})
    endif()
endmacro()

