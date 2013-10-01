# - Find WiX executables
#=============================================================================
# Copyright 2013 Nicolás Alvarez
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(_WIX_VERSIONS 4.0 3.9 3.8 3.7 3.6 3.5 3.0)

foreach(_VERSION ${_WIX_VERSIONS})
    # CMake is a 32-bit process, so on 64-bit systems, its access to the
    # registry is normally redirected to Wow6432Node. However, CMake has
    # explicit logic to look in the 32-bit or 64-bit registry. The policy for
    # resolving registry paths is to get the same registry view as the
    # compiled app would see; in other words, access the 64-bit registry if
    # we're compiling for 64-bit (according to CMAKE_SIZEOF_VOID_P). However,
    # this doesn't work for WiX, as we don't care if we get a 32-bit WiX when
    # compiling 64-bit apps. This is why we need to manually look in both
    # registry keys.
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

function(_WIX_COMPILE source wixobj flags)
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
    CMAKE_PARSE_ARGUMENTS(WIX_AP "" "" "SOURCES;COMPILE_FLAGS;LINK_FLAGS;DEPENDS" ${ARGN})

    set(_objs "")
    foreach(source ${WIX_AP_SOURCES})
        _WIX_COMPILE(${source} _obj "${WIX_AP_COMPILE_FLAGS}")
        set(_objs ${_objs} ${_obj})
    endforeach()

    set(msi_name "${target_name}.msi")
    get_filename_component(basename ${msi_name} NAME_WE)
    add_custom_command(
        OUTPUT ${msi_name} ${basename}.wixpdb
        COMMAND "${WIX_LIGHT_PATH}"
        ARGS -nologo -out "${msi_name}" ${WIX_AP_LINK_FLAGS} ${_objs}
        DEPENDS ${_objs} ${WIX_AP_DEPENDS}
    )
    add_custom_target(${target_name} ALL DEPENDS ${msi_name})
endfunction()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Wix
    REQUIRED_VARS WIX_PATH WIX_CANDLE_PATH WIX_LIGHT_PATH WIX_LIT_PATH
    VERSION_VAR WIX_VERSION)

