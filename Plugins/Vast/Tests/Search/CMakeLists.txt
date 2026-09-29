# tst_fuzzy   FuzzyCore + FuzzyMatcher, no QObject involved. Ranking
#             vectors are ported from the vendored upstream fzy suite.
# tst_search  SearchEngine, LaunchHistoryStore, FileSearchModel, DirectoryWalker

add_executable(tst_fuzzy
    tst_fuzzy.cpp
)

target_link_libraries(tst_fuzzy PRIVATE
    Qt6::Core
    Qt6::Test
    vast-core
)

add_executable(tst_search
    tst_search.cpp
)

# SearchEngine scores through FuzzyMatcher, which lives in vast-core.
target_link_libraries(tst_search PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Test
    vast-core
    vast-search
)

foreach(target IN ITEMS tst_fuzzy tst_search)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
