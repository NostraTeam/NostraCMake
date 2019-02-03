cmake_minimum_required(VERSION 3.9 FATAL_ERROR)

include("${CMAKE_CURRENT_LIST_DIR}/PrivateHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/Utility.cmake")

# Get the directory of this file; this needs to be outside of a function b/c CMAKE_CURRENT_LIST_DIR evaluates to
# the calling file inside of a function.
set(_NOSTRA_CMAKE_LIST_DIR "${CMAKE_CURRENT_LIST_DIR}")

# Helper for nostra_generate_export_header(). See doc of that function.
function(_nostra_generate_export_header_helper TARGET PREFIX OUT_DIR)
    _nostra_check_no_parameters()

    nostra_alias_to_actual_name(TARGET)

    _nostra_check_if_nostra_project()
    _nostra_check_if_lib(${TARGET})

    # Make the prefix upper case
    set(NOSTRA_CMAKE_PREFIX "${PREFIX}")
    string(TOUPPER "${NOSTRA_CMAKE_PREFIX}" NOSTRA_CMAKE_PREFIX)

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if("${NOSTRA_CMAKE_TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
        target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_SHOULD_EXPORT")
    endif()

    get_target_property(NOSTRA_CMAKE_TARGET_TYPE ${TARGET} TYPE)

    if("${NOSTRA_CMAKE_TARGET_TYPE}" STREQUAL "STATIC_LIBRARY")
        target_compile_definitions(${TARGET} 
            PRIVATE 
                "${NOSTRA_CMAKE_PREFIX}_IS_STATIC_LIB")
    endif()

    nostra_get_compiler_id(NOSTRA_COMPILER_ID)

    if("${NOSTRA_COMPILER_ID}" STREQUAL "MSVC")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__declspec(dllexport)")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__declspec(dllimport)")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "") # no export is the default behavior on Windows
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__declspec(deprecated)")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "AppleClang")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "Clang")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    elseif("${NOSTRA_COMPILER_ID}" STREQUAL "GNU")
        set(NOSTRA_CMAKE_EXPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_IMPORT_ATTRIBUTE "__attribute__((visibility(\"default\")))")
        set(NOSTRA_CMAKE_NO_EXPORT_ATTRIBUTE "__attribute__((visibility(\"hidden\")))")
        set(NOSTRA_CMAKE_DEPRECATED_ATTRIBUTE "__attribute__((__deprecated__))")
    else()
        nostra_print_error("The compiler with the ID ${NOSTRA_COMPILER_ID} is not supported.")
    endif()

    # If OUT_DIR is undefined, explicitly define it. This is required b/c the next configure_file() command would put
    # the generated file into the root directory if OUT_DIR is empty/undefined.
    if(NOT DEFINED OUT_DIR)
        set(OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    message("::${_NOSTRA_CMAKE_LIST_DIR}")
    configure_file("${_NOSTRA_CMAKE_LIST_DIR}/../cmake/export.h.in" "${OUT_DIR}/export.h" @ONLY)
endfunction()

#[=[
# Parameters:
#   - TARGET:                The target that the export header is generated for.
#   - OUTPUT_DIR [optional]: The directory that the output file will be put. If this is not given, the output directory
#                            will be CMAKE_CURRENT_BINARY_DIR.
#
# This function works very similar to CMake's generate_export_header() function, but it is usable without enabling C++
# as a language. In addition to that, it is less customizable because the names are pulled from the Nostra convention.
#
# When included, the generated header will provide the following macros:
# - <project prefix>_EXPORT:     Functions that are supposed to be part of the public interface of the library need to
#                                be prefixed with this macro.
# - <project prefix>_NO_EXPORT:  Functions that are not supposed to be part of the public interface of the library need 
#                                to be prefixed with this macro.
# - <project prefix>_DEPRECATED: Functions that are deprecated are supposed to be prefixed with this macro. This is a 
#                                (better) alternative to C++'s attribute [[deprecated]], because it is compatible to C 
#                                and older versions of C++.
# In addition to these macros, the CMake function itself will define the macro <project prefix>_IS_STATIC_LIB if the 
# library that is being build is a static library. If the library is a shared library, the macro is not defined (if the
# macro is defined, it is always defined, it is not required to include the header generated by this function).
#
# Note: Every function should either be explicitly prefixed with <project name>_EXPORT or <project name>_NO_EXPORT,
#       because the default behavior is different from platform to platform.
# Note: This file should not be shared across compilers and platforms. To prevent this, it should only be stored in the
#       build directory, not the source directory.
#
# This function can only be called, if nostra_project() was called first and TARGET needs to be either a
# shared or static library.
#]=]
macro(nostra_generate_export_header TARGET)
    cmake_parse_arguments(FUNC "" "OUTPUT_DIR" "" ${ARGN})

    _nostra_check_if_nostra_project()
    _nostra_check_parameters()

    # Put FUNC_OUTPUT_DIR into quotes to make sure an empty string gets passed if it is not defined
    # That way, the output directory will be the build directory
    _nostra_generate_export_header_helper(${TARGET} ${PROJECT_PREFIX} "${FUNC_OUTPUT_DIR}")
endmacro()
