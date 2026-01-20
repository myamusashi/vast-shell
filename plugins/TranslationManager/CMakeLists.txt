cmake_minimum_required(VERSION 3.16)
project(TranslationManager VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

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
)

target_link_libraries(TranslationManager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

install(TARGETS TranslationManager TranslationManagerplugin
    LIBRARY DESTINATION lib/qt-6/qml/TranslationManager
)
