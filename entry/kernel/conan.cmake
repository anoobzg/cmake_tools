macro(__install_conan_requirements)
    cmake_parse_arguments(conan "" "MSVC_RUNTIME"
        "" ${ARGN})

	set(deps_dir ${CMAKE_BINARY_DIR}/deps/)
	set(conan_file ${CMAKE_SOURCE_DIR}/conanfile.py)

	if(MSVC)
		if(conan_MSVC_RUNTIME AND ${conan_MSVC_RUNTIME} STREQUAL "dynamic")
			__set_global_property(MSVC_RUNTIME_DYNAMIC 1)
		else()
			__set_global_property(MSVC_RUNTIME_DYNAMIC 0)
		endif()
	endif()

	if(EXISTS ${conan_file} AND NOT EXISTS ${deps_dir})
		message(STATUS "__install_conan_deps -> ${deps_dir}")
		file(MAKE_DIRECTORY ${deps_dir})

		set(ARGS "install" "${CMAKE_SOURCE_DIR}" "--output-folder=${deps_dir}")

		if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
			list(APPEND ARGS "-s" "build_type=Debug")
		else()
			list(APPEND ARGS "-s" "build_type=Release")
		endif()

        if(MSVC)
            if(conan_MSVC_RUNTIME AND ${conan_MSVC_RUNTIME} STREQUAL "dynamic")
                list(APPEND ARGS "-s" "compiler.runtime=dynamic")
            else()
                list(APPEND ARGS "-s" "compiler.runtime=static")
            endif()
        endif()

		execute_process(
    		COMMAND "conan" ${ARGS}
    		RESULT_VARIABLE RESULT
    		OUTPUT_VARIABLE OUTPUT
		)
 
		if(NOT RESULT EQUAL "0")
    		message(FATAL_ERROR "__install_conan_deps run conan install failed : ${OUTPUT}")
		else()
    		message("__install_conan_deps run conan install successful : ${OUTPUT}")
		endif()
	endif()

	set(tool_chain_file ${deps_dir}/conan_toolchain.cmake)
	if(EXISTS ${tool_chain_file})
		include(${tool_chain_file})
	else()
		message(STATUS "__install_conan_deps : please use cmaketoolchain to generate conan_toolchain.cmake")
	endif()
endmacro()

macro(__cc_find)
	__normal_message("__cc_find is deprecated, please use find_package instead.")
endmacro(__cc_find)
