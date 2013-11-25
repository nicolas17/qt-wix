# - Find WiX executables
#=============================================================================
# Copyright 2013 Nicolás Alvarez
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

set(_WIX_VERSIONS 3.9 3.8 3.7 3.6 3.5 3.0)

foreach(_VERSION ${_WIX_VERSIONS})
    # CMake is a 32-bit process, so on 64-bit systems, its access to the
    # registry would be normally redirected to Wow6432Node. But CMake has
    # explicit logic to look the same registry area the compiled app would see;
    # in other words, it will access the 64-bit registry if we're compiling
    # for 64-bit (according to CMAKE_SIZEOF_VOID_P).
    # However, WiX is always 32-bit, and will always be in the 32-bit registry
    # This is why we need to manually look in both registry keys.
    list(APPEND _REG_SEARCH_PATHS
        "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Installer XML\\${_VERSION};InstallRoot]"
        "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows Installer XML\\${_VERSION};InstallRoot]"
    )
endforeach()

find_path(
    WIX_PATH
    candle.exe
    PATHS ${_REG_SEARCH_PATHS}
)

execute_process(
    COMMAND "${WIX_PATH}/candle.exe" "-help"
    OUTPUT_VARIABLE _CANDLE_HELP_OUTPUT
)
string(REGEX REPLACE "^([^\n]*)\n.*" "\\1" _CANDLE_HELP_OUTPUT "${_CANDLE_HELP_OUTPUT}")
string(REGEX REPLACE "^(Microsoft \\(R\\) )?Windows Installer Xml Compiler version ([0-9]+(\\.[0-9]+)*)$" "\\2" WIX_VERSION "${_CANDLE_HELP_OUTPUT}")

find_program(WIX_CANDLE_PATH candle.exe PATHS ${WIX_PATH} NO_DEFAULT_PATH)
find_program(WIX_LIGHT_PATH  light.exe  PATHS ${WIX_PATH} NO_DEFAULT_PATH)
find_program(WIX_LIT_PATH    lit.exe    PATHS ${WIX_PATH} NO_DEFAULT_PATH)

function(_WIX_COMPILE wixobj source flags)
    get_filename_component(source ${source} ABSOLUTE)
    get_filename_component(basename ${source} NAME_WE)
    set(OUTPUT_WIXOBJ "${basename}.wixobj")

    add_custom_command(
        OUTPUT ${OUTPUT_WIXOBJ}
        COMMAND "${WIX_CANDLE_PATH}"
        ARGS -nologo ${flags} ${source}
        MAIN_DEPENDENCY ${source}
    )
    set(${wixobj} ${OUTPUT_WIXOBJ} PARENT_SCOPE)
endfunction()

function(WIX_ADD_PRODUCT target_name)
    CMAKE_PARSE_ARGUMENTS(_WIX_AP "" "" "SOURCES;COMPILE_FLAGS;LINK_FLAGS;DEPENDS" ${ARGN})

    set(objs "")
    foreach(source ${_WIX_AP_SOURCES})
        _WIX_COMPILE(obj ${source} "${_WIX_AP_COMPILE_FLAGS}")
        set(objs ${objs} ${obj})
    endforeach()

    set(msi_name "${target_name}.msi")
    get_filename_component(basename ${msi_name} NAME_WE)
    add_custom_command(
        OUTPUT ${msi_name} ${basename}.wixpdb
        COMMAND "${WIX_LIGHT_PATH}"
        ARGS -nologo -out "${msi_name}" ${_WIX_AP_LINK_FLAGS} ${objs}
        DEPENDS ${objs} ${_WIX_AP_DEPENDS}
    )
    add_custom_target(${target_name} ALL DEPENDS ${msi_name})
endfunction()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Wix
    REQUIRED_VARS WIX_PATH WIX_CANDLE_PATH WIX_LIGHT_PATH WIX_LIT_PATH
    VERSION_VAR WIX_VERSION)

