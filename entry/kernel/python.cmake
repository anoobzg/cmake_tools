# default find python3
find_package(Python3 COMPONENTS Interpreter Development)

if(Python3_FOUND AND Python3_Development_FOUND)
	__normal_message("Find Python3 ${Python3_VERSION}")
	__normal_message("INCLUDES : ${Python3_INCLUDE_DIRS}")
	__normal_message("LIBRARIES : ${Python3_LIBRARIES}")
	__normal_message("RUNTIME LIBRARIES : ${Python3_RUNTIME_LIBRARIES}")
	__normal_message("LIBRARY DIRS : ${Python3_LIBRARY_DIRS}")
	__normal_message("Python3_EXECUTABLE : ${Python3_EXECUTABLE}")
	if(NOT Python3_EXECUTABLE)
		__normal_message(WARNING "Python3_EXECUTABLE Must be Set.")
	endif()
	set(PYTHON ${Python3_EXECUTABLE})

	set(PYTHON_INCLUDE_DIR ${Python3_INCLUDE_DIRS})
	set(PYTHON_INCLUDE_DIRS ${Python3_INCLUDE_DIRS})
	list(GET Python3_LIBRARIES 0 Python3_LIBRARIES_RELEASE)
	list(LENGTH Python3_LIBRARIES LIB_LEN)
	if(${LIB_LEN} GREATER 1)
		list(GET Python3_LIBRARIES 1 Python3_LIBRARIES_RELEASE)
	endif()
	set(Python3_LIBRARIES_DEBUG ${Python3_LIBRARIES_RELEASE})
	if(${LIB_LEN} GREATER 3)
		list(GET Python3_LIBRARIES 3 Python3_LIBRARIES_DEBUG)
	endif()
	__normal_message("Python3 Debug LIBRARIES : ${Python3_LIBRARIES_DEBUG}")
	__normal_message("Python3 Release LIBRARIES : ${Python3_LIBRARIES_RELEASE}")
	set(PYTHON_LIBRARY Python3)
else()
	__normal_message("Can't find Python3.")
endif()


macro(__copy_python_pyc)
	message(STATUS ${PYTHON_ROOT})

	add_custom_target(__copy_python_pyc ALL COMMENT "copy third party dll!")
	__set_target_folder(__copy_python_pyc CMakePredefinedTargets)

	add_custom_command(TARGET __copy_python_pyc PRE_BUILD
		COMMAND ${CMAKE_COMMAND} -E make_directory "${BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>"
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${PYTHON_ROOT}/PYC/"
			"${BIN_OUTPUT_DIR}/$<$<CONFIG:Debug>:Debug>$<$<CONFIG:Release>:Release>"
		)

endmacro()

macro(__wrap_python_target target)
	set_target_properties(${target} PROPERTIES DEBUG_POSTFIX "_d")
	set_target_properties(${target} PROPERTIES SUFFIX ".pyd")
endmacro()
