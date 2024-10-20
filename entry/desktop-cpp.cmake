list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/module/)

message(STATUS ${CMAKE_MODULE_PATH})
include(kernel/targets)
include(kernel/conan)