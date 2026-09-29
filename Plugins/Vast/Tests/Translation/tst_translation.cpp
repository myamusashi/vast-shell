#include <qcoreapplication.h>
#include <qguiapplication.h>
#include <qlocale.h>
#include <qobject.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>

#include <memory>

#include "../../Translation/TranslationManager.hpp"

namespace {

    // Context and source string from translations/id_ID.ts.
    const char* const     kContext = "FormatTimeUtils";
    const char* const     kJustNow = "just now";

    [[nodiscard]] QString translated(const char* source) {
        return QGuiApplication::translate(kContext, source);
    }

} // namespace

class TestTranslation : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void init();

    void currentLanguageDefaultsToEnUs();
    void availableLanguagesListsBothCatalogues();

    void loadTranslationInstallsTheIndonesianCatalogue();
    void loadTranslationEmitsLanguageChangedExactlyOnce();
    void loadTranslationSetsTheDefaultLocale();
    void theEnglishCatalogueLoadsButTranslatesToTheSourceString();
    void aSecondLanguageTranslatesTheSameContext();

    void loadingAnUnknownLanguageFails();
    void aFailedLoadLeavesTheCurrentLanguageAlone();
    void theDefaultTranslationPathIsNotUsable();

    void setCurrentLanguageWithTheSameValueEmitsNothing();
    void setCurrentLanguageSwitchesTheCatalogue();
    void setCurrentLanguageToAnUnknownValueKeepsTheCurrentOne();

  private:
    std::unique_ptr<TranslationManager> mManager;
};

void TestTranslation::init() {
    mManager = std::make_unique<TranslationManager>();
}

void TestTranslation::currentLanguageDefaultsToEnUs() {
    // TranslationManager.cpp:14.
    QCOMPARE(mManager->currentLanguage(), QStringLiteral("en_US"));
}

void TestTranslation::availableLanguagesListsBothCatalogues() {
    // LanguagePage.qml:22-24 renders this list.
    QCOMPARE(mManager->availableLanguages(), (QStringList{QStringLiteral("en_US"), QStringLiteral("id_ID")}));
}

void TestTranslation::loadTranslationInstallsTheIndonesianCatalogue() {
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    QCOMPARE(mManager->currentLanguage(), QStringLiteral("id_ID"));
    // End to end: the .qm was parsed, installed and consulted by Qt's lookup.
    QCOMPARE(translated(kJustNow), QStringLiteral("Saat ini"));
}

void TestTranslation::loadTranslationEmitsLanguageChangedExactlyOnce() {
    QSignalSpy spy(mManager.get(), &TranslationManager::languageChanged);

    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    QCOMPARE(spy.count(), 1);
}

void TestTranslation::loadTranslationSetsTheDefaultLocale() {
    // QLocale::setDefault is process-wide (TranslationManager.cpp:50), so pin the C locale first.
    QLocale::setDefault(QLocale::c());

    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    QVERIFY2(QLocale().name().startsWith(QLatin1String("id")), qPrintable(QLocale().name()));
}

void TestTranslation::theEnglishCatalogueLoadsButTranslatesToTheSourceString() {
    // en_US.qm is a 16-byte empty catalogue: it loads, but has no messages, so the source string comes
    // back.
    QVERIFY(mManager->loadTranslation(QStringLiteral("en_US"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    QCOMPARE(mManager->currentLanguage(), QStringLiteral("en_US"));
    QCOMPARE(translated(kJustNow), QString::fromLatin1(kJustNow));
}

void TestTranslation::aSecondLanguageTranslatesTheSameContext() {
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    // A second entry, so the check is not tied to one string.
    QCOMPARE(translated("N/A"), QStringLiteral("T/A"));
}

void TestTranslation::loadingAnUnknownLanguageFails() {
    QVERIFY(!mManager->loadTranslation(QStringLiteral("zz_ZZ"), QStringLiteral(VAST_TRANSLATIONS_DIR)));
}

void TestTranslation::aFailedLoadLeavesTheCurrentLanguageAlone() {
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));
    QCOMPARE(mManager->currentLanguage(), QStringLiteral("id_ID"));

    QVERIFY(!mManager->loadTranslation(QStringLiteral("zz_ZZ"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    // A bad pick leaves the language and the installed catalogue intact.
    QCOMPARE(mManager->currentLanguage(), QStringLiteral("id_ID"));
    QCOMPARE(translated(kJustNow), QStringLiteral("Saat ini"));
}

void TestTranslation::theDefaultTranslationPathIsNotUsable() {
    // DEFAULT_TRANSLATION_PATH is ":/translations" (TranslationManager.hpp:19) and nothing installs it
    // there, so Configs.qml always passes an explicit path.
    QVERIFY(!mManager->loadTranslation(QStringLiteral("id_ID")));

    QCOMPARE(mManager->currentLanguage(), QStringLiteral("en_US"));
}

void TestTranslation::setCurrentLanguageWithTheSameValueEmitsNothing() {
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    QSignalSpy spy(mManager.get(), &TranslationManager::languageChanged);
    mManager->setCurrentLanguage(QStringLiteral("id_ID"));

    // The early return at TranslationManager.cpp:26-27.
    QCOMPARE(spy.count(), 0);
}

void TestTranslation::setCurrentLanguageSwitchesTheCatalogue() {
    // setCurrentLanguage reuses mTranslationPath, so point it at the fixtures first.
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));
    QVERIFY(mManager->loadTranslation(QStringLiteral("en_US"), QStringLiteral(VAST_TRANSLATIONS_DIR)));
    QCOMPARE(mManager->currentLanguage(), QStringLiteral("en_US"));

    QSignalSpy spy(mManager.get(), &TranslationManager::languageChanged);
    mManager->setCurrentLanguage(QStringLiteral("id_ID"));

    QCOMPARE(mManager->currentLanguage(), QStringLiteral("id_ID"));
    QCOMPARE(spy.count(), 1);
    QCOMPARE(translated(kJustNow), QStringLiteral("Saat ini"));
}

void TestTranslation::setCurrentLanguageToAnUnknownValueKeepsTheCurrentOne() {
    QVERIFY(mManager->loadTranslation(QStringLiteral("id_ID"), QStringLiteral(VAST_TRANSLATIONS_DIR)));

    mManager->setCurrentLanguage(QStringLiteral("zz_ZZ"));

    // The warning branch at TranslationManager.cpp:29-30.
    QCOMPARE(mManager->currentLanguage(), QStringLiteral("id_ID"));
}

QTEST_MAIN(TestTranslation)
#include "tst_translation.moc"
