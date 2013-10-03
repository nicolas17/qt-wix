cmake_minimum_required(VERSION 2.8)

project(kf5-installer NONE)
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

find_path(QT_LIBRARIES_PATH NAMES Qt5Core.dll PATH_SUFFIXES bin)
report_path(QT_LIBRARIES_PATH "Qt5 libraries")
find_path(QT_PLUGINS_PATH NAMES platforms/qwindows.dll PATH_SUFFIXES plugins)
report_path(QT_PLUGINS_PATH "Qt5 plugins")
find_path(QT_EXAMPLES_PATH NAMES widgets/widgets/lineedits/lineedits.exe PATH_SUFFIXES examples)
report_path(QT_EXAMPLES_PATH "Qt5 examples")

wix_add_product(lineedits
    SOURCES main.wxs qt.wxs
    COMPILE_FLAGS -arch x86
    LINK_FLAGS
        -b qt5=${QT_LIBRARIES_PATH}
        -b qt5examples="${QT_EXAMPLES_PATH}"
        -b qt5plugins="${QT_PLUGINS_PATH}"
        -b srcdir="${CMAKE_SOURCE_DIR}"
)
