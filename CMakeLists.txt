cmake_minimum_required(VERSION 3.22)
project(VastPlugins VERSION 1.0 LANGUAGES CXX C)

# Nix stdenv feeds every buildInput via NIX_CFLAGS_COMPILE, so CMake records
# all of them (Qt parent include/ dirs, the C++ stdlib, glibc, ...) as
# implicit and strips them from build rules and compile_commands.json.
# Normal builds still compile (the compiler wrapper re-injects the flags),
# but clang tooling that parses compile_commands.json directly
# (clazy-standalone, clangd, clang-tidy) then fails on any header resolved
# through a stripped dir, e.g. qbytearray.h -> <QtCore/qrefcount.h> or even
# <utility>. Fix: drop Nix store dirs from the implicit lists so real target
# includes stay explicit, and re-inject the toolchain defaults (C++ stdlib,
# C library, compiler resource dir) as explicit -isystem flags — those are
# never target includes, so nothing else can bring them back. Dependency
# include dirs (Qt, glib, ...) come back via normal target usage
# requirements and are intentionally not duplicated here. Must run before any
# target is created; no-op on non-Nix systems.
set(VAST_TOOLCHAIN_REGEX "nix/store.*(gcc|clang|glibc|compiler-rt|libcxx)")

set(VAST_CXX_TOOLCHAIN_DIRS ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
list(FILTER VAST_CXX_TOOLCHAIN_DIRS INCLUDE REGEX "${VAST_TOOLCHAIN_REGEX}")

set(VAST_C_TOOLCHAIN_DIRS ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
list(FILTER VAST_C_TOOLCHAIN_DIRS INCLUDE REGEX "${VAST_TOOLCHAIN_REGEX}")

set(VAST_NIX_TOOLCHAIN_DIRS ${VAST_CXX_TOOLCHAIN_DIRS})
foreach(VAST_DIR IN LISTS VAST_C_TOOLCHAIN_DIRS)
    if(NOT VAST_DIR IN_LIST VAST_NIX_TOOLCHAIN_DIRS)
        list(APPEND VAST_NIX_TOOLCHAIN_DIRS "${VAST_DIR}")
    endif()
endforeach()

# Collect in CXX implicit order first: <stdlib.h> resolves via #include_next
# from the gcc C++ dirs, so glibc must stay after them. Appending the C list
# first (or concatenating C then CXX) inverts that order and breaks the
foreach(VAST_LANG C CXX)
    list(FILTER CMAKE_${VAST_LANG}_IMPLICIT_INCLUDE_DIRECTORIES EXCLUDE REGEX "nix/store")
endforeach()

foreach(VAST_DIR IN LISTS VAST_NIX_TOOLCHAIN_DIRS)
    add_compile_options(-isystem${VAST_DIR})
endforeach()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

find_package(Qt6 6.3 REQUIRED COMPONENTS Core DBus Gui Qml Quick Network Sql)
find_package(PkgConfig REQUIRED)

add_compile_options(
    -Wall -Wextra -Wpedantic -Wshadow -Wconversion
    -Wold-style-cast -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wfloat-equal -Woverloaded-virtual
    -Wsign-conversion -Wredundant-decls -Wswitch
    -Wunreachable-code
)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(-Wunused-lambda-capture)
endif()

# pipewire's pkg-config target defines _REENTRANT for Vast.Audio only; a
# per-target define difference invalidates PCH reuse (-Winvalid-pch), so
# match it project-wide (same workaround quickshell applies).
add_compile_definitions(_REENTRANT)

set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

if(NOT DEFINED INSTALL_QMLDIR)
    execute_process(
        COMMAND ${QT_QMAKE_EXECUTABLE} -query QML2_IMPORT_PATH
        OUTPUT_VARIABLE QT_QML_IMPORT_PATH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    if(QT_QML_IMPORT_PATH)
        file(RELATIVE_PATH QML_REL_PATH "/" "${QT_QML_IMPORT_PATH}")
        set(INSTALL_QMLDIR "${QML_REL_PATH}")
    else()
        set(INSTALL_QMLDIR "${CMAKE_INSTALL_LIBDIR}/qt6/qml")
    endif()
endif()
message(STATUS "QML install dir: ${CMAKE_INSTALL_PREFIX}/${INSTALL_QMLDIR}")

include(Plugins/cmake/pch.cmake)
include(Plugins/cmake/qml-module.cmake)

add_subdirectory(Plugins/third_party/mcu)
add_subdirectory(Plugins/third_party/fzy-wrapper)
add_subdirectory(Plugins/Vast)

# After all targets: add_dependencies() on pchsets / generated-code libs only
# resolves for targets defined above, so these includes must stay last.
include(Plugins/cmake/clazy-lint.cmake)
include(Plugins/cmake/tidy-lint.cmake)
