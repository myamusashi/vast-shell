cmake_minimum_required(VERSION 3.22)
project(AudioProfilesPlugin VERSION 1.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(QML_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/qml/AudioProfiles")

find_package(Qt6 6.3 REQUIRED COMPONENTS Core Qml)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)

qt_add_library(AudioProfilesPlugin SHARED)
qt_add_library(AudioProfilesQmlPlugin SHARED)

qt_add_qml_module(AudioProfilesPlugin
    URI AudioProfiles
    VERSION 1.0
	PLUGIN_TARGET AudioProfilesQmlPlugin
	OUTPUT_DIRECTORY "${QML_OUTPUT_DIR}"
    SOURCES
        AudioProfilesModel.h
        AudioProfilesModel.cpp
        AudioProfilesWatcher.h
        AudioProfilesWatcher.cpp
)

target_include_directories(AudioProfilesPlugin PRIVATE ${PIPEWIRE_INCLUDE_DIRS})
target_link_libraries(AudioProfilesPlugin PRIVATE
    Qt6::Core
    Qt6::Qml
    ${PIPEWIRE_LIBRARIES}
)
target_compile_options(AudioProfilesPlugin PRIVATE ${PIPEWIRE_CFLAGS_OTHER})

target_link_libraries(AudioProfilesQmlPlugin PRIVATE
    AudioProfilesPlugin
    Qt6::Core
    Qt6::Qml
)

file(MAKE_DIRECTORY "${QML_OUTPUT_DIR}")
file(WRITE "${QML_OUTPUT_DIR}/qmldir"
    "module AudioProfiles\n"
    "plugin AudioProfilesQmlPlugin\n"
    "classname AudioProfilesPlugin\n"
    "typeinfo AudioProfiles.qmltypes\n"
)

set(QML_INSTALL_DEST "${CMAKE_INSTALL_LIBDIR}/qt-6/qml/AudioProfiles")

install(TARGETS AudioProfilesPlugin
    LIBRARY DESTINATION "${QML_INSTALL_DEST}"
)

install(TARGETS AudioProfilesQmlPlugin
    LIBRARY DESTINATION "${QML_INSTALL_DEST}"
)

install(
    DIRECTORY "${QML_OUTPUT_DIR}/"
    DESTINATION "${QML_INSTALL_DEST}"
    FILES_MATCHING
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
)
