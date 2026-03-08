cmake_minimum_required(VERSION 3.16)
project(KeylockState VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

find_package(Qt6 REQUIRED COMPONENTS Quick)

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

set(QML_OUTPUT_DIR "${CMAKE_BINARY_DIR}/KeylockState")

qt_add_qml_module(KeylockState
    URI KeylockState
    VERSION 1.0
	PLUGIN_TARGET KeylockStateQmlPlugin
	OUTPUT_DIRECTORY ${QML_OUTPUT_DIR}
    SOURCES
        KeylockState.cpp
        KeylockState.h
)

target_link_libraries(KeylockState PRIVATE Qt6::Quick)

if(NOT DEFINED QML_INSTALL_DIR)
    set(QML_INSTALL_DIR "lib/qt-6/qml")
endif()

set(PLUGIN_TARGET_NAME "KeylockStateQmlPlugin")

set_target_properties(KeylockState PROPERTIES
    INSTALL_RPATH "\$ORIGIN"
)

set_target_properties(${PLUGIN_TARGET_NAME} PROPERTIES
    INSTALL_RPATH "\$ORIGIN"
)

install(TARGETS KeylockState
    LIBRARY DESTINATION ${QML_INSTALL_DIR}/KeylockState
    RUNTIME DESTINATION ${QML_INSTALL_DIR}/KeylockState
)

install(TARGETS ${PLUGIN_TARGET_NAME}
    LIBRARY DESTINATION ${QML_INSTALL_DIR}/KeylockState
    RUNTIME DESTINATION ${QML_INSTALL_DIR}/KeylockState
)

install(DIRECTORY "${QML_OUTPUT_DIR}/"
    DESTINATION ${QML_INSTALL_DIR}/KeylockState
    FILES_MATCHING
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
        PATTERN "*.so" EXCLUDE
        PATTERN "*.dll" EXCLUDE
)

if(EXISTS ${QML_OUTPUT_DIR}/KeylockState.qmltypes)
    install(FILES
        ${QML_OUTPUT_DIR}/KeylockState.qmltypes
        DESTINATION ${QML_INSTALL_DIR}/KeylockState
        OPTIONAL
    )
endif()
