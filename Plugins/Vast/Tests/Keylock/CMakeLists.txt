#   tst_keylock   KeyEventDecoder's two modes, plus the QML property contract
#
# Nothing here constructs a Keylock: its constructor opens real /dev/input
# devices, which is why the event logic was extracted into KeyEventDecoder.
# The one Keylock case walks the metaObject and needs no instance.

add_executable(tst_keylock
    tst_keylock.cpp
)

target_link_libraries(tst_keylock PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-keylock
)

foreach(target IN ITEMS tst_keylock)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
