cmake_minimum_required(VERSION 3.15)
project(RafaelIA_core C ASM)

option(RAFAELIA_BUILD_ADDON "Build RafaelIA addon library" ON)

if (NOT RAFAELIA_BUILD_ADDON)
    return()
endif ()

if (NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    message(STATUS "RafaelIA addon skipped: requires AArch64 (current: ${CMAKE_SYSTEM_PROCESSOR})")
    return()
endif ()

add_library(RafaelIA_core STATIC
    asm/arm64/vectra_pulse.S
)

target_include_directories(RafaelIA_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set_target_properties(RafaelIA_core PROPERTIES
    OUTPUT_NAME "rafaelia_core"
)
