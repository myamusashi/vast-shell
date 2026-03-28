cmake_minimum_required(VERSION 3.22)
project(VastPlugin VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(QML_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/qml/Vast")

find_package(Qt6 6.3 REQUIRED COMPONENTS Core Gui Qml Quick Concurrent Sql)
qt_policy(SET QTP0001 NEW)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PIPEWIRE REQUIRED IMPORTED_TARGET libpipewire-0.3)
pkg_check_modules(DDCUTIL REQUIRED IMPORTED_TARGET ddcutil)

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

qt_add_library(VastPlugin SHARED)
qt_add_library(VastQmlPlugin SHARED)

qt_add_qml_module(VastPlugin
    URI Vast
    VERSION 1.0
    PLUGIN_TARGET VastQmlPlugin
    OUTPUT_DIRECTORY "${QML_OUTPUT_DIR}"
    SOURCES
        AudioProfilesModel.hpp
        AudioProfilesModel.cpp
        AudioProfilesWatcher.hpp
        AudioProfilesWatcher.cpp
        BrightnessManager.hpp
        BrightnessManager.cpp
        KeylockState.hpp
        KeylockState.cpp
        LyricsProvider.cpp
        LyricsProvider.hpp
        TranslationManager.hpp
        TranslationManager.cpp
        ScreenRecorder.hpp
        ScreenRecorder.cpp
        ImageCache.cpp
        ImageCache.hpp
        Clipboard/ClipboardEntry.hpp
        Clipboard/ClipboardModel.hpp
        Clipboard/ClipboardModel.cpp
        Clipboard/ClipboardManager.hpp
        Clipboard/ClipboardManager.cpp
        Clipboard/ClipboardWatcher.hpp
        Clipboard/ClipboardWatcher.cpp
        Clipboard/ClipboardDatabase.hpp
        Clipboard/ClipboardDatabase.cpp
        Search/FuzzyMatcher.hpp
        Search/FuzzyMatcher.cpp
        Search/SearchResult.hpp
        Search/SearchResult.cpp
        Search/SearchEngine.hpp
        Search/SearchEngine.cpp
)

target_include_directories(VastPlugin SYSTEM PRIVATE
    ${PIPEWIRE_INCLUDE_DIRS}
    ${DDCUTIL_INCLUDE_DIRS}
	${CMAKE_CURRENT_SOURCE_DIR}/Clipboard
    ${CMAKE_CURRENT_SOURCE_DIR}/Search
)

target_link_libraries(VastPlugin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
    Qt6::Concurrent
	Qt6::Sql
    ${PIPEWIRE_LIBRARIES}
    ${DDCUTIL_LIBRARIES}
)

target_compile_options(VastPlugin PRIVATE
    ${PIPEWIRE_CFLAGS_OTHER}
    ${DDCUTIL_CFLAGS_OTHER}
)

target_link_libraries(VastQmlPlugin PRIVATE
    VastPlugin
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)

file(MAKE_DIRECTORY "${QML_OUTPUT_DIR}")
file(WRITE "${QML_OUTPUT_DIR}/qmldir"
    "module Vast\n"
    "plugin VastQmlPlugin\n"
    "classname VastPlugin\n"
    "typeinfo Vast.qmltypes\n"
)

include(GNUInstallDirs)

execute_process(
    COMMAND ${QT_QMAKE_EXECUTABLE} -query QML2_IMPORT_PATH
    OUTPUT_VARIABLE QT_QML_IMPORT_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(DEFINED QML_INSTALL_DEST)
    # explicitly passed in (e.g. from Nix)
elseif(QT_QML_IMPORT_PATH)
    file(RELATIVE_PATH QML_REL_PATH "/" "${QT_QML_IMPORT_PATH}")
    set(QML_INSTALL_DEST "${QML_REL_PATH}/Vast")
else()
    set(QML_INSTALL_DEST "${CMAKE_INSTALL_LIBDIR}/qt6/qml/Vast")
endif()

set_target_properties(VastPlugin    PROPERTIES INSTALL_RPATH "\$ORIGIN")
set_target_properties(VastQmlPlugin PROPERTIES INSTALL_RPATH "\$ORIGIN")

install(TARGETS VastPlugin
    LIBRARY DESTINATION "${QML_INSTALL_DEST}"
    RUNTIME DESTINATION "${QML_INSTALL_DEST}"
)

install(TARGETS VastQmlPlugin
    LIBRARY DESTINATION "${QML_INSTALL_DEST}"
    RUNTIME DESTINATION "${QML_INSTALL_DEST}"
)

install(
    DIRECTORY "${QML_OUTPUT_DIR}/"
    DESTINATION "${QML_INSTALL_DEST}"
    FILES_MATCHING
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
        PATTERN "*.qml"
        PATTERN "*.so"  EXCLUDE
        PATTERN "*.dll" EXCLUDE
)

if(EXISTS ${QML_OUTPUT_DIR}/Vast.qmltypes)
    install(FILES
        ${QML_OUTPUT_DIR}/Vast.qmltypes
        DESTINATION ${QML_INSTALL_DEST}
        OPTIONAL
    )
endif()
