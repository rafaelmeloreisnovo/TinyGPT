cmake_minimum_required(VERSION 3.15)
project(RafaelIA_core C ASM)

option(RAFAELIA_BUILD_ADDON "Build RafaelIA addon library" ON)

if (NOT RAFAELIA_BUILD_ADDON)
    return()
endif ()

set(RAFAELIA_CORE_SOURCES
    rmr_engine.c
)

if (CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)$")
    list(APPEND RAFAELIA_CORE_SOURCES asm/arm64/vectra_pulse.S)
else ()
    message(STATUS "RafaelIA ASM core skipped: requires AArch64 (current: ${CMAKE_SYSTEM_PROCESSOR})")
endif ()

add_library(RafaelIA_core STATIC ${RAFAELIA_CORE_SOURCES})

target_include_directories(RafaelIA_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

set_target_properties(RafaelIA_core PROPERTIES
    OUTPUT_NAME "rafaelia_core"
)

if (UNIX)
    target_link_libraries(RafaelIA_core PUBLIC m)
endif ()
