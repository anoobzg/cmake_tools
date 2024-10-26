#message wrapper , assert

macro(__fatal_message msg)
    message(FATAL_ERROR "#### FATAL : ${msg}")
endmacro()

macro(__normal_message msg)
    message(STATUS "#### : ${msg}")
endmacro()

macro(__assert_target target)
	if(NOT TARGET ${target})
		__fatal_message("${target} must exist!!!")
	endif()
endmacro()