#   tst_colorutils         ColorUtils: blending, fromString, HCT
#   tst_utilsfile          Read + Write: round trips and failure paths
#   tst_paletteanimator    PaletteAnimator: duration, interpolation
#   tst_bluetoothagent     BluetoothAgentManager + adaptor over a private bus
#
# tst_bluetoothagent is the one suite that needs dbus-daemon on PATH; it is
# available inside the flake devShell that CI enters, and the suite skips the
# bus-dependent slots rather than failing when it is not. Qt6::DBus is required
# for the include path: vast_module passes Qt::DBus through privately, so a
# consumer gets the library as $<LINK_ONLY:> and not the headers.

add_executable(tst_colorutils
    tst_colorutils.cpp
)

target_link_libraries(tst_colorutils PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Test
    vast-utils
)

add_executable(tst_utilsfile
    tst_utilsfile.cpp
)

target_link_libraries(tst_utilsfile PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-utils
)

add_executable(tst_paletteanimator
    tst_paletteanimator.cpp
)

target_link_libraries(tst_paletteanimator PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Test
    vast-utils
)

add_executable(tst_bluetoothagent
    tst_bluetoothagent.cpp
)

target_link_libraries(tst_bluetoothagent PRIVATE
    Qt6::Core
    Qt6::DBus
    Qt6::Qml
    Qt6::Test
    vast-utils
)

foreach(target IN ITEMS tst_colorutils tst_utilsfile tst_paletteanimator tst_bluetoothagent)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
