#   tst_lrcparser         LrcParser: LRC and plain-text parsing
#   tst_lyricscache       LyricsCache: key, envelope, miss conditions
#   tst_lyricsscheduler   LyricsScheduler: position, boundaries, signals
#
# No fixtures or network: inputs are literal LRC strings or in-memory wordLines.
# Qt6::Gui is unneeded here (QtCore headers only); Qt6::Qml is for
# <qqmlintegration.h> in the headers. LyricsProvider is not covered: its
# endpoint is a hardcoded URL with no injectable base.

add_executable(tst_lrcparser
    tst_lrcparser.cpp
)

target_link_libraries(tst_lrcparser PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-lyrics
)

add_executable(tst_lyricscache
    tst_lyricscache.cpp
)

target_link_libraries(tst_lyricscache PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-lyrics
)

add_executable(tst_lyricsscheduler
    tst_lyricsscheduler.cpp
)

target_link_libraries(tst_lyricsscheduler PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Test
    vast-lyrics
)

foreach(target IN ITEMS tst_lrcparser tst_lyricscache tst_lyricsscheduler)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
endforeach()
