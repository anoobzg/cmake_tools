macro(__add_boost_target module)
	__source_recurse(${CMAKE_CURRENT_SOURCE_DIR} SRC)
	__source_recurse(${boost_includes}boost/${module}/ HEADER)
	
	__add_real_target(boost_${module} dll SOURCE ${SRC} ${HEADER}
										  INC ${CMAKE_CURRENT_SOURCE_DIR}/../../
										  DEF BOOST_ALL_DYN_LINK
										  INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/../../)
endmacro()

macro(__find_boost_root)
	find_path(boost_INCLUDE_DIR boost/core/typeinfo.hpp
		HINTS "$ENV{CX_THIRDPARTY_ROOT}/include/"
		PATHS "/usr/include/")
endmacro()

macro(__include_boost)
	__cc_find(Boost)
	__assert_parameter(BOOST_INCLUDE_DIRS)
	include_directories(${BOOST_INCLUDE_DIRS})
endmacro()