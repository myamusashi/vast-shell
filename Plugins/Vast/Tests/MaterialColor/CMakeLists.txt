# tst_palette            M3 invariants over the wallpaper fixtures
# tst_colormaterial      ColorMaterial wrapper: debounce, async, error state
# tst_spec_parity        sourceColor -> 64 roles vs the reference
# tst_quantizer_parity   image bytes -> sourceColor vs the reference

set(VAST_TEST_WALLPAPER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data/wallpapers")
set(VAST_TEST_GOLDEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data/golden")
set(VAST_TEST_QUANTIZER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data/quantizer")
set(VAST_TEST_QUANTIZER_GOLDEN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/data/quantizer-golden")

# Shared by the two suites that read the wallpaper manifest.
add_library(vast-test-wallpaper-fixtures STATIC
    WallpaperFixtures.cpp
    WallpaperFixtures.hpp
)

target_include_directories(vast-test-wallpaper-fixtures PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(vast-test-wallpaper-fixtures PUBLIC
    VAST_TEST_FIXTURE_DIR="${VAST_TEST_WALLPAPER_DIR}"
)
target_link_libraries(vast-test-wallpaper-fixtures PUBLIC
    Qt6::Core
)

add_executable(tst_palette
    tst_palette.cpp
)

target_link_libraries(tst_palette PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    vast-materialcolor
    vast-test-wallpaper-fixtures
)

add_executable(tst_colormaterial
    tst_colormaterial.cpp
)

# Links the module rather than recompiling ColorMaterial.cpp, so the shipped
# class and its QML_ELEMENT machinery are what gets tested.
target_link_libraries(tst_colormaterial PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Test
    vast-utils
    vast-test-wallpaper-fixtures
)

add_executable(tst_spec_parity
    tst_spec_parity.cpp
)

target_compile_definitions(tst_spec_parity PRIVATE
    VAST_TEST_GOLDEN_DIR="${VAST_TEST_GOLDEN_DIR}"
)

target_link_libraries(tst_spec_parity PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    vast-materialcolor
)

add_executable(tst_quantizer_parity
    tst_quantizer_parity.cpp
)

target_compile_definitions(tst_quantizer_parity PRIVATE
    VAST_TEST_QUANTIZER_DIR="${VAST_TEST_QUANTIZER_DIR}"
    VAST_TEST_QUANTIZER_GOLDEN_DIR="${VAST_TEST_QUANTIZER_GOLDEN_DIR}"
)

target_link_libraries(tst_quantizer_parity PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    vast-materialcolor
)

foreach(target IN ITEMS tst_palette tst_colormaterial tst_spec_parity tst_quantizer_parity)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
