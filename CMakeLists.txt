cmake_minimum_required(VERSION 2.8)

project(qt-wix NONE)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}")
# I don't actually know what version I need, but I'm testing with 3.7
find_package(Wix 3.7 REQUIRED)

function(report_path var description)
    if (${var})
        message(STATUS "Found ${description}: ${${var}}")
    else()
        message(SEND_ERROR "Couldn't find ${description}")
    endif()
endfunction()

find_path(QT_PATH NAMES bin/Qt5Core.dll)
report_path(QT_PATH "Qt5")

wix_add_product(qt-wix
    SOURCES main.wxs qt.wxs
    COMPILE_FLAGS -arch x86
    LINK_FLAGS
        -b qt5=${QT_PATH}
        -b srcdir="${CMAKE_SOURCE_DIR}"
        -sice:ICE64
)
