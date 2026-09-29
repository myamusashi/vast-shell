#   tst_clipboarddatabase   ClipboardDatabase: schema, CRUD, dedup, pruning
#   tst_clipboardmodel      ClipboardModel: roles, ordering, fuzzy filter
#   tst_clipboardhelpers    ClipboardEntry, ClipboardContentClassifier,
#                           LoopbackGuard, ClipboardPreviewCache, htmlToPlainText
#   tst_clipboardmanager    ClipboardManager end to end over a seeded database

add_executable(tst_clipboarddatabase
    tst_clipboarddatabase.cpp
)

target_link_libraries(tst_clipboarddatabase PRIVATE
    Qt6::Core
    Qt6::Sql
    Qt6::Test
    vast-clipboard
)

add_executable(tst_clipboardmodel
    tst_clipboardmodel.cpp
)

target_link_libraries(tst_clipboardmodel PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    vast-clipboard
)

add_executable(tst_clipboardhelpers
    tst_clipboardhelpers.cpp
)

target_link_libraries(tst_clipboardhelpers PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Test
    vast-clipboard
)

add_executable(tst_clipboardmanager
    tst_clipboardmanager.cpp
)

target_link_libraries(tst_clipboardmanager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Sql
    Qt6::Test
    vast-clipboard
)

foreach(target IN ITEMS tst_clipboarddatabase tst_clipboardmodel tst_clipboardhelpers tst_clipboardmanager)
    add_test(NAME ${target} COMMAND ${target} ${VAST_TEST_ARGS})
    set_tests_properties(${target} PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
endforeach()
