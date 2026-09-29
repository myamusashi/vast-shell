#   tst_brightnessstore    BrightnessProfileStore
#   tst_brightnessdisplay  DisplayWorker, clampPercent, backlight I/O
#   tst_brightnessmanager  BrightnessManager without hardware
#
# PkgConfig::DDCUTIL must be declared here as well: Plugins/Vast/Brightness
# declares it without GLOBAL, so the imported target is invisible in this
# directory. vast-brightness propagates it as $<LINK_ONLY:>, which links but does
# not add the include path that BrightnessManager.hpp needs.
#
# tst_brightnessstore deliberately omits it: it includes only
# BrightnessProfileStore.hpp, which has no ddcutil dependency.

pkg_check_modules(DDCUTIL REQUIRED IMPORTED_TARGET ddcutil)

add_executable(tst_brightnessstore
    tst_brightnessstore.cpp
)

target_link_libraries(tst_brightnessstore PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-brightness
)

add_executable(tst_brightnessdisplay
    tst_brightnessdisplay.cpp
)

target_link_libraries(tst_brightnessdisplay PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    PkgConfig::DDCUTIL
    vast-brightness
)

add_executable(tst_brightnessmanager
    tst_brightnessmanager.cpp
)

target_link_libraries(tst_brightnessmanager PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    PkgConfig::DDCUTIL
    vast-brightness
)

foreach(target IN ITEMS tst_brightnessstore tst_brightnessdisplay tst_brightnessmanager)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
