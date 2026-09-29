#   tst_translation   TranslationManager: catalogue load, switching, failures
#
# Qt6::Qml is required: loadTranslation calls qmlEngine() and retranslate().
# Qt6::Gui is required: the success path calls QGuiApplication::installTranslator,
# so this binary needs QTEST_MAIN and the offscreen platform.
#
# The catalogues are checked in (translations/*.qm). DEFAULT_TRANSLATION_PATH is
# ":/translations" and nothing installs it there, which is why the suite passes
# the on-disk directory.

add_executable(tst_translation
    tst_translation.cpp
)

target_link_libraries(tst_translation PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Test
    vast-translation
)

target_compile_definitions(tst_translation PRIVATE
    VAST_TRANSLATIONS_DIR="${CMAKE_SOURCE_DIR}/translations"
)

add_test(NAME tst_translation COMMAND tst_translation ${VAST_TEST_ARGS})
set_tests_properties(tst_translation PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")
