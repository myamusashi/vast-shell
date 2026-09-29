#   tst_audioprofiles  AudioProfilesModel + formatProfileName
#   tst_audiocards     AudioCard, AudioCardsModel, watchers
#   tst_audiodevices   AudioDevicesModel
#
# No fixtures: inputs are hex colours, struct input_event records and in-memory
# palettes.

add_executable(tst_audioprofiles
    tst_audioprofiles.cpp
)

target_link_libraries(tst_audioprofiles PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-audio
)

add_executable(tst_audiocards
    tst_audiocards.cpp
)

target_link_libraries(tst_audiocards PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-audio
)

add_executable(tst_audiodevices
    tst_audiodevices.cpp
)

target_link_libraries(tst_audiodevices PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-audio
)

foreach(target IN ITEMS tst_audioprofiles tst_audiocards tst_audiodevices)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
