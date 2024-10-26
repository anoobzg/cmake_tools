# base build info

if(NOT PROJECT_VERSION_MAJOR)
    set(PROJECT_VERSION_MAJOR 0)
endif()

if(NOT PROJECT_VERSION_MINOR)
    set(PROJECT_VERSION_MINOR 0)
endif()

if(NOT PROJECT_VERSION_PATCH)
    set(PROJECT_VERSION_PATCH 0)
endif()

if(NOT PROJECT_BUILD_ID)
    set(PROJECT_BUILD_ID 0)
endif()

if(NOT PROJECT_VERSION_EXTRA)
    set(PROJECT_VERSION_EXTRA "alpha")
endif()

if(NOT BUILD_OS)
    set(BUILD_OS "empty")
endif()

if(NOT ORGANIZATION)
    set(ORGANIZATION "empty")
endif()

if(NOT BUNDLE_NAME)
    set(BUNDLE_NAME "empty")
endif()

string(TIMESTAMP BUILD_TIME "%y-%m-%d %H:%M")
set(BUILD_INFO_HEAD "BUILDINFO_H_  // ${PROJECT_NAME} ${BUILD_TIME}")

__get_main_git_hash(MAIN_GIT_HASH)

if(EXISTS ${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in)
    __normal_message(" __build_info_header ${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in")
    configure_file(${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in
            ${CMAKE_BINARY_DIR}/buildinfo.h)
else()
    __normal_message(" __build_info_header failed . ${CMAKE_CURRENT_LIST_DIR}/buildinfo.h.in")
endif()