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

function(__get_submodule_git_hash sub _git_hash)
	message("__get_submodule_git_hash sub=${sub}")
	if(EXISTS "${CMAKE_SOURCE_DIR}/${sub}/.git")
		execute_process(
			COMMAND git rev-parse --short -q HEAD
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/${sub}
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

function(__get_branch_name _branch)
	message("__get_branch_name branch=${_branch}")
	# 分支名
	if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
		EXECUTE_PROCESS(
			COMMAND git symbolic-ref --short -q HEAD
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			OUTPUT_VARIABLE MAGE_VERSION_GIT_HEAD_BRANCH
			OUTPUT_STRIP_TRAILING_WHITESPACE
		)
	endif()
	
	if(NOT MAGE_VERSION_GIT_HEAD_BRANCH)
		set(MAGE_VERSION_GIT_HEAD_BRANCH "NO_MAGE_VERSION_GIT_HEAD_BRANCH")
	endif()
	MESSAGE("-- Current Git Branch: ${MAGE_VERSION_GIT_HEAD_BRANCH}")
	set(${_branch} "${MAGE_VERSION_GIT_HEAD_BRANCH}" PARENT_SCOPE)
endfunction()

function(__get_last_commit_time _commit_time)
	# 最后提交时间
	EXECUTE_PROCESS(
		COMMAND git log -1  --date=format:"%Y-%m-%d %H:%M:%S" --format=%cd
		OUTPUT_VARIABLE MAGE_VERSION_LAST_COMMIT_TIME
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	if(NOT MAGE_VERSION_LAST_COMMIT_TIME)
		set(MAGE_VERSION_LAST_COMMIT_TIME "NO_MAGE_VERSION_LAST_COMMIT_TIME")
	endif()
	MESSAGE("-- Git Last Commit Time: ${MAGE_VERSION_LAST_COMMIT_TIME}")
	set(${_commit_time} "${MAGE_VERSION_LAST_COMMIT_TIME}" PARENT_SCOPE)
endfunction()
