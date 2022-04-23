#target OpenMP::OpenMP_CXX

macro(__enable_openmp)
	find_package(OpenMP REQUIRED)
	if(OPENMP_FOUND)
		message("__enable_opemmp Find OpenMP.")
		if(ANDROID)
			message(WARNING "OpenMP_CXX_LIBRARIES:  ${OpenMP_CXX_LIBRARIES}")
			message(WARNING "OpenMP_CXX_FLAGS:  ${OpenMP_CXX_FLAGS}")
		endif()
		if(TARGET OpenMP::OpenMP_CXX)
			message(STATUS "OpenMP TARGET OpenMP::OpenMP_CXX Imported.")
		endif()
	endif()
endmacro()

macro(__use_openmp target)
	
endmacro()

#macro(__add_openmp_lib arg1)
#    find_library(OPENOMP_LIBRARIES
#             NAMES omp
#             PATHS "/usr/local/lib")
#    message(STATUS ${OPENOMP_LIBRARIES})
#	if(OPENOMP_LIBRARIES)
#		target_link_libraries(${arg1} PRIVATE ${OPENOMP_LIBRARIES})
#	endif()
#endmacro()

#macro(__disable_openmp)
#	string(REPLACE "-openmp" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
#	string(REPLACE "-openmp" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
#
#	include(AdjustToolFlags)
#	AdjustToolFlags(CMAKE_C_FLAGS REMOVALS "/-openmp")
#	AdjustToolFlags(CMAKE_CXX_FLAGS REMOVALS "/-openmp")
#	AdjustToolFlags(CMAKE_EXE_LINKER_FLAGS REMOVALS "${OpenMP_EXE_LINKER_FLAGS}")
#endmacro()

