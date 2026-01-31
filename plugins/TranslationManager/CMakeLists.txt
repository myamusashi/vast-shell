cmake_minimum_required(VERSION 3.16)
project(TranslationManager VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

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

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_add_qml_module(TranslationManager
    URI TranslationManager
    VERSION 1.0
    SOURCES
        TranslationManager.h
        TranslationManager.cpp
    NO_PLUGIN_OPTIONAL
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/TranslationManager
)

target_link_libraries(TranslationManager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

if(NOT DEFINED QML_INSTALL_DIR)
    set(QML_INSTALL_DIR "lib/qt-6/qml")
endif()

set_target_properties(TranslationManager PROPERTIES
    INSTALL_RPATH "\$ORIGIN:${CMAKE_INSTALL_PREFIX}/${QML_INSTALL_DIR}/TranslationManager"
)

set_target_properties(TranslationManagerplugin PROPERTIES
    INSTALL_RPATH "\$ORIGIN:${CMAKE_INSTALL_PREFIX}/${QML_INSTALL_DIR}/TranslationManager"
)

install(TARGETS TranslationManager TranslationManagerplugin
    LIBRARY DESTINATION ${QML_INSTALL_DIR}/TranslationManager
)

install(FILES 
    ${CMAKE_BINARY_DIR}/TranslationManager/qmldir
    DESTINATION ${QML_INSTALL_DIR}/TranslationManager
)

if(EXISTS ${CMAKE_BINARY_DIR}/TranslationManager/TranslationManager.qmltypes)
    install(FILES 
        ${CMAKE_BINARY_DIR}/TranslationManager/TranslationManager.qmltypes
        DESTINATION ${QML_INSTALL_DIR}/TranslationManager
    )
endif()
