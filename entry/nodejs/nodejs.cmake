# Node.js utilities for CMake
# 
# GENERIC TOOLS: These macros are designed to work with ANY Node.js/npm project
# Supports: Vue.js, React, Angular, Svelte, and any other npm-based frontend framework
# 
# Main Functions:
#   - __find_nodejs()                           Find Node.js and npm executables
#   - __build_nodejs_project(src dst [FORCE])   Build any npm project (generic)
#   - __add_nodejs_build_target(name src dst)   Create rebuild target (generic)
#   - __npm_install(dir)                        Install dependencies
#   - __npm_build(dir script)                   Run build script
#
# Legacy Aliases (deprecated):
#   - __build_fluidd_frontend()     → Use __build_nodejs_project()
#   - __add_fluidd_build_target()   → Use __add_nodejs_build_target()
#
# Requirements for target projects:
#   - package.json with "build" script
#   - Build output in dist/ directory
#   - dist/index.html as entry point

# Find Node.js and npm executables
macro(__find_nodejs)
    # Try to find node executable
    find_program(NODEJS_EXECUTABLE 
        NAMES node nodejs
        DOC "Node.js executable"
    )
    
    # Try to find npm executable
    find_program(NPM_EXECUTABLE
        NAMES npm npm.cmd
        DOC "npm executable"
    )
    
    if(NODEJS_EXECUTABLE)
        # Get Node.js version
        execute_process(
            COMMAND ${NODEJS_EXECUTABLE} --version
            OUTPUT_VARIABLE NODEJS_VERSION
            ERROR_VARIABLE NODEJS_VERSION_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE NODEJS_VERSION_RESULT
        )
        
        # Clean up version string (remove any extra whitespace or newlines)
        string(STRIP "${NODEJS_VERSION}" NODEJS_VERSION)
        string(REGEX REPLACE "[\r\n]+" "" NODEJS_VERSION "${NODEJS_VERSION}")
        
        if(NODEJS_VERSION_RESULT EQUAL 0 AND NODEJS_VERSION)
            message(STATUS "Found Node.js: ${NODEJS_EXECUTABLE} (${NODEJS_VERSION})")
        else()
            message(WARNING "Node.js found but version check failed: ${NODEJS_VERSION_ERROR}")
        endif()
    else()
        message(WARNING "Node.js not found! Please install Node.js from https://nodejs.org/")
    endif()
    
    if(NPM_EXECUTABLE)
        # On Windows, ensure we use the .cmd extension
        set(NPM_CMD "${NPM_EXECUTABLE}")
        if(WIN32 AND NOT NPM_CMD MATCHES "\\.cmd$")
            if(EXISTS "${NPM_CMD}.cmd")
                set(NPM_CMD "${NPM_CMD}.cmd")
            endif()
        endif()
        
        # Get npm version
        execute_process(
            COMMAND ${NPM_CMD} --version
            OUTPUT_VARIABLE NPM_VERSION
            ERROR_VARIABLE NPM_VERSION_ERROR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_STRIP_TRAILING_WHITESPACE
            RESULT_VARIABLE NPM_VERSION_RESULT
        )
        
        # Clean up version string (remove any extra whitespace or newlines)
        string(STRIP "${NPM_VERSION}" NPM_VERSION)
        string(REGEX REPLACE "[\r\n]+" "" NPM_VERSION "${NPM_VERSION}")
        
        if(NPM_VERSION_RESULT EQUAL 0 AND NPM_VERSION)
            message(STATUS "Found npm: ${NPM_EXECUTABLE} (v${NPM_VERSION})")
        else()
            message(WARNING "npm found but version check failed: ${NPM_VERSION_ERROR}")
            message(STATUS "Tried to execute: ${NPM_CMD}")
        endif()
    else()
        message(WARNING "npm not found! Please install Node.js with npm from https://nodejs.org/")
    endif()
endmacro()

# Helper macro to get the correct npm command
# On Windows, npm needs .cmd extension
macro(__get_npm_command output_var)
    if(NPM_EXECUTABLE)
        set(${output_var} "${NPM_EXECUTABLE}")
        if(WIN32 AND NOT ${output_var} MATCHES "\\.cmd$")
            if(EXISTS "${${output_var}}.cmd")
                set(${output_var} "${${output_var}}.cmd")
            endif()
        endif()
    else()
        set(${output_var} "")
    endif()
endmacro()

# Check if npm dependencies are installed
function(__check_npm_dependencies source_dir result_var)
    if(EXISTS "${source_dir}/package.json" AND EXISTS "${source_dir}/node_modules")
        set(${result_var} TRUE PARENT_SCOPE)
    else()
        set(${result_var} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Install npm dependencies
macro(__npm_install source_dir)
    if(NOT NPM_EXECUTABLE)
        message(FATAL_ERROR "npm not found! Cannot install dependencies.")
    endif()
    
    # Get correct npm command (with .cmd on Windows)
    __get_npm_command(NPM_CMD)
    
    message(STATUS "Installing npm dependencies in ${source_dir}...")
    execute_process(
        COMMAND ${NPM_CMD} install
        WORKING_DIRECTORY ${source_dir}
        RESULT_VARIABLE NPM_INSTALL_RESULT
        OUTPUT_VARIABLE NPM_INSTALL_OUTPUT
        ERROR_VARIABLE NPM_INSTALL_ERROR
    )
    
    if(NOT NPM_INSTALL_RESULT EQUAL 0)
        message(FATAL_ERROR "npm install failed!\n${NPM_INSTALL_ERROR}")
    else()
        message(STATUS "npm install completed successfully")
    endif()
endmacro()

# Build npm project
macro(__npm_build source_dir build_script)
    if(NOT NPM_EXECUTABLE)
        message(FATAL_ERROR "npm not found! Cannot build project.")
    endif()
    
    # Get correct npm command (with .cmd on Windows)
    __get_npm_command(NPM_CMD)
    
    message(STATUS "Building npm project in ${source_dir}...")
    message(STATUS "Running: npm run ${build_script}")
    
    execute_process(
        COMMAND ${NPM_CMD} run ${build_script}
        WORKING_DIRECTORY ${source_dir}
        RESULT_VARIABLE NPM_BUILD_RESULT
        OUTPUT_VARIABLE NPM_BUILD_OUTPUT
        ERROR_VARIABLE NPM_BUILD_ERROR
    )
    
    if(NOT NPM_BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "npm run ${build_script} failed!\n${NPM_BUILD_ERROR}")
    else()
        message(STATUS "npm build completed successfully")
    endif()
endmacro()

# Main macro to build Node.js/npm project
# Usage: __build_nodejs_project(source_dir output_dir [FORCE])
# This is a generic macro for building any Node.js project with npm
macro(__build_nodejs_project source_dir output_dir)
    set(options FORCE)
    set(oneValueArgs "")
    set(multiValueArgs "")
    cmake_parse_arguments(BUILD_NODEJS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    # Find Node.js and npm
    __find_nodejs()
    
    if(NOT NODEJS_EXECUTABLE OR NOT NPM_EXECUTABLE)
        message(WARNING "Node.js or npm not found. Skipping Fluidd frontend build.")
        message(WARNING "Please install Node.js from https://nodejs.org/ to build the frontend.")
        return()
    endif()
    
    # Check if source directory exists
    if(NOT EXISTS "${source_dir}/package.json")
        message(WARNING "package.json not found in ${source_dir}")
        message(WARNING "Skipping Fluidd frontend build.")
        return()
    endif()
    
    set(DIST_DIR "${source_dir}/dist")
    set(BUILD_NEEDED FALSE)
    
    # Check if build is needed
    if(BUILD_NODEJS_FORCE)
        message(STATUS "FORCE option specified, will rebuild Node.js project")
        set(BUILD_NEEDED TRUE)
    elseif(NOT EXISTS "${DIST_DIR}/index.html")
        message(STATUS "Node.js project not built yet (dist/index.html missing)")
        set(BUILD_NEEDED TRUE)
    else()
        message(STATUS "Node.js project already built at ${DIST_DIR}")
        set(BUILD_NEEDED FALSE)
    endif()
    
    # Build if needed
    if(BUILD_NEEDED)
        message(STATUS "========================================")
        message(STATUS "Building Node.js Project")
        message(STATUS "========================================")
        message(STATUS "Source: ${source_dir}")
        message(STATUS "Output: ${DIST_DIR}")
        
        # Install dependencies if needed
        __check_npm_dependencies(${source_dir} DEPS_INSTALLED)
        if(NOT DEPS_INSTALLED)
            message(STATUS "Installing dependencies...")
            __npm_install(${source_dir})
        else()
            message(STATUS "Dependencies already installed")
        endif()
        
        # Build the project
        __npm_build(${source_dir} "build")
        
        message(STATUS "========================================")
        message(STATUS "Node.js Project Build Complete")
        message(STATUS "========================================")
    endif()
    
    # Copy dist to output directory
    if(EXISTS "${DIST_DIR}")
        message(STATUS "Copying build output to ${output_dir}...")
        file(REMOVE_RECURSE "${output_dir}")
        file(COPY "${DIST_DIR}/" DESTINATION "${output_dir}")
        message(STATUS "Build output copied successfully")
    else()
        message(WARNING "Build output directory not found: ${DIST_DIR}")
    endif()
endmacro()

# Compatibility alias for old name
macro(__build_fluidd_frontend source_dir output_dir)
    message(DEPRECATION "__build_fluidd_frontend is deprecated, use __build_nodejs_project instead")
    __build_nodejs_project(${source_dir} ${output_dir} ${ARGN})
endmacro()

# Add custom target to rebuild Node.js project
# Usage: __add_nodejs_build_target(target_name source_dir output_dir)
function(__add_nodejs_build_target target_name source_dir output_dir)
    # Find Node.js and npm
    __find_nodejs()
    
    if(NOT NODEJS_EXECUTABLE OR NOT NPM_EXECUTABLE)
        message(WARNING "Node.js or npm not found. Cannot create build target ${target_name}")
        return()
    endif()
    
    # Get correct npm command (with .cmd on Windows)
    __get_npm_command(NPM_CMD)
    if(NOT NPM_CMD)
        message(WARNING "Cannot determine npm command. Cannot create build target ${target_name}")
        return()
    endif()
    
    # Create custom target
    add_custom_target(${target_name}
        COMMENT "Building Node.js project..."
    )
    
    # Add install dependencies command
    add_custom_command(TARGET ${target_name}
        PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Installing npm dependencies..."
        COMMAND ${NPM_CMD} install
        WORKING_DIRECTORY ${source_dir}
        COMMENT "Installing npm dependencies"
    )
    
    # Add build command
    add_custom_command(TARGET ${target_name}
        PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Building Node.js project..."
        COMMAND ${NPM_CMD} run build
        WORKING_DIRECTORY ${source_dir}
        COMMENT "Building with npm"
    )
    
    # Add copy command
    add_custom_command(TARGET ${target_name}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Copying to ${output_dir}..."
        COMMAND ${CMAKE_COMMAND} -E remove_directory "${output_dir}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${source_dir}/dist" "${output_dir}"
        COMMENT "Copying build output to destination"
    )
    
    message(STATUS "Created build target: ${target_name}")
    message(STATUS "  Run 'cmake --build . --target ${target_name}' to rebuild project")
endfunction()

# Compatibility alias for old name
function(__add_fluidd_build_target target_name source_dir output_dir)
    message(DEPRECATION "__add_fluidd_build_target is deprecated, use __add_nodejs_build_target instead")
    __add_nodejs_build_target(${target_name} ${source_dir} ${output_dir})
endfunction()

