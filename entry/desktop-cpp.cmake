list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/module/)
include(kernel/message)

include(kernel/common)
__normal_message("__CMAKE_MODULE_PATH: ${__CMAKE_MODULE_PATH}")

include(kernel/cxx)
include(kernel/targets)
include(kernel/conan)
include(kernel/python)
include(kernel/install)

include(utils/files)
include(utils/git)
include(utils/buildinfo)
include(utils/property)

include(qt/qt)