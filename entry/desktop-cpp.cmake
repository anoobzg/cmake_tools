list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR} ${CMAKE_CURRENT_LIST_DIR}/module/)

include(kernel/message)
include(kernel/common)
include(kernel/cxx)
include(kernel/targets)
include(kernel/conan)
include(kernel/python)

include(utils/files)
include(utils/git)
include(utils/buildinfo)
include(utils/property)

include(qt/qt5)