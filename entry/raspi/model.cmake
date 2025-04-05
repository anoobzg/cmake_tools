# detect raspi informations
# __RASPI_REVISION
# __RASPI_DEVICETREE_MODEL

# definations
# __RASPI_5 
# __RASPI_4
# ...
# __RASPI_INVALID

macro(__detect_raspi)
    # raspi Revision
    execute_process(
        COMMAND bash -c "cat /proc/cpuinfo | grep Revision | awk '{print $3}'"
        OUTPUT_VARIABLE RPI_REVISION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    execute_process(
        COMMAND bash -c "cat /sys/firmware/devicetree/base/model | tr -d '\\0'"
        OUTPUT_VARIABLE RPI_MODEL_RAW
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      

    set(__RASPI_REVISION ${RPI_REVISION})
    set(__RASPI_DEVICETREE_MODEL ${RPI_MODEL_RAW})

    add_definitions(-D__RASPI_DEVICETREE_MODEL="${__RASPI_DEVICETREE_MODEL}")

    if(__RASPI_REVISION STREQUAL "a03111" OR __RASPI_REVISION STREQUAL "b03111")
        add_definitions(-D__RASPI_4)
    elseif(__RASPI_REVISION STREQUAL "d04170")
        add_definitions(-D__RASPI_5)
    else()
        add_definitions(-D__RASPI_INVALID)
    endif()

    message(STATUS "__RASPI_REVISION : ${__RASPI_REVISION}")
    message(STATUS "__RASPI_DEVICETREE_MODEL : ${__RASPI_DEVICETREE_MODEL}")
endmacro()
