function(__install_runable)
    cmake_parse_arguments(arg "" "TARGET" "" ${ARGN})
    if(NOT arg_TARGET)
        __error_message("__install_runable. No target specified")
    endif()

    if(CC_BC_WIN)
        install(TARGETS ${arg_TARGET} RUNTIME DESTINATION .)
    else()
    endif()
endfunction()

function(__install_dynamic)
    
endfunction()
