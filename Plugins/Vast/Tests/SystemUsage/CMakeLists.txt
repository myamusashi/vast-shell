add_executable(tst_systemusage
    tst_systemusage.cpp
)

target_link_libraries(tst_systemusage PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    Qt6::DBus
    vast-systemusage
    vast-jobs
)

add_test(NAME tst_systemusage COMMAND tst_systemusage ${VAST_TEST_ARGS})
