function(__get_main_git_hash _git_hash)
	if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
		execute_process(
			COMMAND git rev-parse HEAD
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			OUTPUT_VARIABLE GIT_HASH
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	endif()
	if(NOT GIT_HASH)
		set(GIT_HASH "NO_GIT_COMMIT_HASH_DEFINED")
	endif()
	if(BUILD_VERSION_HASH)
		set(GIT_HASH "${BUILD_VERSION_HASH}")
	endif()
	set(${_git_hash} "${GIT_HASH}" PARENT_SCOPE)
endfunction()