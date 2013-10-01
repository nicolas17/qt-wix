cmake_minimum_required(VERSION 2.8)

project(kf5-installer NONE)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}")
# I don't actually know what version I need, but I'm testing with 3.7
find_package(Wix 3.7 REQUIRED)

find_package(Qt5 COMPONENTS Core)

get_target_property(QTCORE_LOCATION Qt5::Core LOCATION)
get_filename_component(QTCORE_DIR ${QTCORE_LOCATION} PATH)

wix_add_product(lineedits
    SOURCES main.wxs qt.wxs
    COMPILE_FLAGS -arch x86
    LINK_FLAGS
        -b qt5=${QTCORE_DIR}
        -b qt5examples="${QTCORE_DIR}/../examples"
        -b qt5plugins="${QTCORE_DIR}/../plugins"
        -b srcdir="${CMAKE_SOURCE_DIR}"
)
