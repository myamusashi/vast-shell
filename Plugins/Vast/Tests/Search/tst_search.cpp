#include <qabstractitemmodel.h>
#include <qcoreapplication.h>
#include <qdir.h>
#include <qelapsedtimer.h>
#include <qeventloop.h>
#include <qfile.h>
#include <qobject.h>
#include <qsettings.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qscopedpointer.h>
#include <qstringlist.h>
#include <qtest.h>
#include <qtemporarydir.h>
#include <memory>
#include <utility>
#include <qvariant.h>

#include "../../Search/DirectoryWalker.hpp"
#include "../../Search/FileSearchModel.hpp"
#include "../../Search/LaunchHistoryStore.hpp"
#include "../../FuzzyCore.hpp"
#include "../../FuzzyMatcher.hpp"
#include "../../Search/SearchEngine.hpp"

namespace {

    constexpr int K_TIMEOUT_MS = 30000;

    template <typename Predicate>
    bool spinUntil(Predicate predicate) {
        QElapsedTimer timer;
        timer.start();
        while (!predicate() && timer.elapsed() < K_TIMEOUT_MS)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        return predicate();
    }

    // Stands in for a desktop entry; searchApps only reads these four fields.
    class AppEntry : public QObject {
        Q_OBJECT
        Q_PROPERTY(QString id READ id CONSTANT)
        Q_PROPERTY(QString name READ name CONSTANT)
        Q_PROPERTY(QString genericName READ genericName CONSTANT)
        Q_PROPERTY(QString comment READ comment CONSTANT)

      public:
        AppEntry(QString id, QString name, QString genericName, QString comment) :
            mId(std::move(id)), mName(std::move(name)), mGenericName(std::move(genericName)), mComment(std::move(comment)) {}

        QString id() const {
            return mId;
        }
        QString name() const {
            return mName;
        }
        QString genericName() const {
            return mGenericName;
        }
        QString comment() const {
            return mComment;
        }

      private:
        QString mId;
        QString mName;
        QString mGenericName;
        QString mComment;
    };

    // AppEntry with a settable name, for testing cache invalidation.
    class RenameableEntry : public QObject {
        Q_OBJECT
        Q_PROPERTY(QString id READ id CONSTANT)
        Q_PROPERTY(QString name READ name WRITE setName)
        Q_PROPERTY(QString genericName READ genericName CONSTANT)
        Q_PROPERTY(QString comment READ comment CONSTANT)

      public:
        RenameableEntry(QString id, QString name, QString genericName, QString comment) :
            mId(std::move(id)), mName(std::move(name)), mGenericName(std::move(genericName)), mComment(std::move(comment)) {}

        QString id() const {
            return mId;
        }
        QString name() const {
            return mName;
        }
        void setName(const QString& name) {
            mName = name;
        }
        QString genericName() const {
            return mGenericName;
        }
        QString comment() const {
            return mComment;
        }

      private:
        QString mId;
        QString mName;
        QString mGenericName;
        QString mComment;
    };

    // The walker emits directories too, so filter counts by fileIsDir.
    int countFiles(const QVariantList& entries) {
        int files = 0;
        for (const QVariant& entry : entries)
            if (!entry.toMap().value(QStringLiteral("fileIsDir")).toBool())
                ++files;
        return files;
    }

    QVariantMap fileEntry(const QString& name, const QString& relativePath, bool isDir = false) {
        const QString normalized = vast::FuzzyMatcher::normalizeText(relativePath);
        return {

            {QStringLiteral("fileName"), name},
            {QStringLiteral("filePath"), QStringLiteral("/tmp/root/") + relativePath},
            {QStringLiteral("relativePath"), relativePath},
            {QStringLiteral("relativePathNorm"), normalized},
            {QStringLiteral("relativePathUtf8"), normalized.toUtf8()},
            {QStringLiteral("fileSize"), 42},
            {QStringLiteral("fileModified"), QVariant()},
            {QStringLiteral("fileIsDir"), isDir},
        };
    }

} // namespace

class TestSearch : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void init();
    void cleanup();

    // LaunchHistoryStore
    void unknownAppHasZeroRecency();
    void recordingALaunchRaisesRecency();
    void repeatedLaunchesRaiseFrequencyComponent();
    void clearHistoryResetsRecency();
    void historyLimitSignalFiresOnlyOnChange();
    void historyLimitEvictsOldestFirst();
    void historyPersistsAcrossInstances();

    // SearchEngine: app search
    void emptyQueryReturnsAllAppsByRecency();
    void emptyQueryIgnoresNonObjectEntries();
    void appSearchRanksExactNameFirst();
    void appSearchIsCaseAndAccentInsensitive();
    void appSearchMatchesSecondaryFields();
    void appSearchThresholdFiltersWeakMatches();
    void appSearchRecencyBreaksScoreTies();
    void appSearchIsDeterministic();
    void appSearchToleratesDroppedCharacter();
    void editDistanceFallbackStaysBelowAppThreshold();
    void appCacheInvalidatesOnRename();
    void appCacheEvictsRemovedApps();

    // SearchEngine: file search
    void fileSearchRanksMatchesByScore();
    void fileSearchThresholdFiltersWeakMatches();
    void fileSearchEmptyQueryClearsResults();
    void fileSearchIsPathAware();
    void staleFileSearchIsDiscarded();
    void clearFileResultsEmptiesModel();
    void thresholdSettersNotifyOnlyOnChange();

    // FileSearchModel
    void modelExposesFileListViewRoles();
    void modelDataMatchesEntries();
    void modelResetEmitsModelReset();
    void modelRejectsOutOfRangeIndex();

    // DirectoryWalker
    void walkerCollectsFilesRecursively();
    void walkerRespectsMaxDepth();
    void walkerSkipsHiddenByDefault();
    void walkerIncludesHiddenWhenAsked();
    void walkerAppliesNameFilters();
    void walkerIgnoresEmptyRoots();
    void walkingFlagTracksTheWalk();
};

// Redirect QSettings away from the real launcher history.
void TestSearch::initTestCase() {
    static QTemporaryDir settingsDir;
    QVERIFY(settingsDir.isValid());
    QSettings::setDefaultFormat(QSettings::IniFormat);
    QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDir.path());
}

void TestSearch::init() {
    vast::LaunchHistoryStore store;
    store.clearHistory();
}

void TestSearch::cleanup() {
    vast::LaunchHistoryStore().clearHistory();
}

void TestSearch::unknownAppHasZeroRecency() {
    vast::LaunchHistoryStore store;
    QCOMPARE(store.recencyScore(QStringLiteral("never-launched")), 0.0);
}

void TestSearch::recordingALaunchRaisesRecency() {
    vast::LaunchHistoryStore store;
    store.clearHistory();
    QCOMPARE(store.recencyScore(QStringLiteral("firefox.desktop")), 0.0);

    store.recordLaunch(QStringLiteral("firefox.desktop"));
    QVERIFY2(store.recencyScore(QStringLiteral("firefox.desktop")) > 0.0, "a just-recorded launch must score above zero");
}

void TestSearch::repeatedLaunchesRaiseFrequencyComponent() {
    vast::LaunchHistoryStore store;
    store.clearHistory();
    store.recordLaunch(QStringLiteral("a.desktop"));
    const double first = store.recencyScore(QStringLiteral("a.desktop"));
    for (int i = 0; i < 5; ++i)
        store.recordLaunch(QStringLiteral("a.desktop"));
    QVERIFY2(store.recencyScore(QStringLiteral("a.desktop")) > first, "repeat launches must raise the frequency term");
}

void TestSearch::clearHistoryResetsRecency() {
    vast::LaunchHistoryStore store;
    store.recordLaunch(QStringLiteral("a.desktop"));
    QVERIFY(store.recencyScore(QStringLiteral("a.desktop")) > 0.0);

    store.clearHistory();
    QCOMPARE(store.recencyScore(QStringLiteral("a.desktop")), 0.0);
}

void TestSearch::historyLimitSignalFiresOnlyOnChange() {
    vast::LaunchHistoryStore store;
    QSignalSpy               spy(&store, &vast::LaunchHistoryStore::historyLimitChanged);

    store.setHistoryLimit(store.historyLimit());
    QCOMPARE(spy.count(), 0);

    store.setHistoryLimit(store.historyLimit() + 1);
    QCOMPARE(spy.count(), 1);
}

void TestSearch::historyLimitEvictsOldestFirst() {
    vast::LaunchHistoryStore store;
    store.setHistoryLimit(3);
    store.clearHistory();

    // Eviction sorts on a millisecond stamp, so space the launches out.
    for (int i = 0; i < 6; ++i) {
        store.recordLaunch(QStringLiteral("app%1.desktop").arg(i));
        QTest::qWait(5);
    }

    // The three most recent survive.
    QVERIFY(store.recencyScore(QStringLiteral("app5.desktop")) > 0.0);
    QVERIFY(store.recencyScore(QStringLiteral("app4.desktop")) > 0.0);
    QVERIFY(store.recencyScore(QStringLiteral("app3.desktop")) > 0.0);
    QCOMPARE(store.recencyScore(QStringLiteral("app0.desktop")), 0.0);
    QCOMPARE(store.recencyScore(QStringLiteral("app1.desktop")), 0.0);
    QCOMPARE(store.recencyScore(QStringLiteral("app2.desktop")), 0.0);
}

void TestSearch::historyPersistsAcrossInstances() {
    {
        vast::LaunchHistoryStore store;
        store.clearHistory();
        store.recordLaunch(QStringLiteral("persisted.desktop"));
    }
    vast::LaunchHistoryStore reopened;
    QVERIFY2(reopened.recencyScore(QStringLiteral("persisted.desktop")) > 0.0, "history must survive a store being recreated, as it does across shell restarts");
}

void TestSearch::emptyQueryReturnsAllAppsByRecency() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            hot(new AppEntry(QStringLiteral("hot.desktop"), QStringLiteral("Hot"), {}, {}));
    QScopedPointer<AppEntry>            cold(new AppEntry(QStringLiteral("cold.desktop"), QStringLiteral("Cold"), {}, {}));

    engine->recordLaunch(QStringLiteral("hot.desktop"));

    const QVariantList result = engine->searchApps({QVariant::fromValue(cold.data()), QVariant::fromValue(hot.data())}, QString());
    QCOMPARE(result.size(), 2);
    QCOMPARE(result.first().value<QObject*>(), hot.data());
}

void TestSearch::emptyQueryIgnoresNonObjectEntries() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            app(new AppEntry(QStringLiteral("a.desktop"), QStringLiteral("Alpha"), {}, {}));

    const QVariantList                  result = engine->searchApps({42, QStringLiteral("nonsense"), QVariant::fromValue(app.data())}, QString());
    QCOMPARE(result.size(), 1);
    QCOMPARE(result.first().value<QObject*>(), app.data());
}

void TestSearch::appSearchRanksExactNameFirst() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            exact(new AppEntry(QStringLiteral("e.desktop"), QStringLiteral("Firefox"), {}, {}));
    QScopedPointer<AppEntry>            partial(new AppEntry(QStringLiteral("p.desktop"), QStringLiteral("Firefox Nightly"), {}, {}));
    QScopedPointer<AppEntry>            other(new AppEntry(QStringLiteral("o.desktop"), QStringLiteral("Thunderbird"), {}, {}));

    const QVariantList                  result =
        engine->searchApps({QVariant::fromValue(other.data()), QVariant::fromValue(partial.data()), QVariant::fromValue(exact.data())}, QStringLiteral("firefox"));
    QVERIFY(result.size() >= 2);
    QCOMPARE(result.first().value<QObject*>(), exact.data());
}

void TestSearch::appSearchIsCaseAndAccentInsensitive() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            accented(new AppEntry(QStringLiteral("a.desktop"), QStringLiteral("Café"), {}, {}));
    QScopedPointer<AppEntry>            other(new AppEntry(QStringLiteral("o.desktop"), QStringLiteral("Thunderbird"), {}, {}));

    for (const QString& query : {QStringLiteral("cafe"), QStringLiteral("CAFÉ"), QStringLiteral("CafÉ")}) {
        const QVariantList result = engine->searchApps({QVariant::fromValue(other.data()), QVariant::fromValue(accented.data())}, query);
        QVERIFY2(!result.isEmpty(), qPrintable(QStringLiteral("query %1 found nothing").arg(query)));
        QCOMPARE(result.first().value<QObject*>(), accented.data());
    }
}

void TestSearch::appSearchMatchesSecondaryFields() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            byComment(new AppEntry(QStringLiteral("c.desktop"), QStringLiteral("Zebra"), {}, QStringLiteral("A web browser")));
    QScopedPointer<AppEntry>            other(new AppEntry(QStringLiteral("o.desktop"), QStringLiteral("Thunderbird"), {}, {}));

    const QVariantList                  result = engine->searchApps({QVariant::fromValue(other.data()), QVariant::fromValue(byComment.data())}, QStringLiteral("browser"));
    QVERIFY2(!result.isEmpty(), "a comment-only match must still be found");
    QCOMPARE(result.first().value<QObject*>(), byComment.data());
}

void TestSearch::appSearchThresholdFiltersWeakMatches() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            weak(new AppEntry(QStringLiteral("w.desktop"), QStringLiteral("Terminal"), {}, {}));
    QScopedPointer<AppEntry>            strong(new AppEntry(QStringLiteral("s.desktop"), QStringLiteral("Kotex"), QStringLiteral("Kotex terminal emulator"), {}));

    const QVariantList                  low = engine->searchApps({QVariant::fromValue(weak.data()), QVariant::fromValue(strong.data())}, QStringLiteral("kotex"));
    QVERIFY(!low.isEmpty());

    engine->setAppThreshold(10.0);
    const QVariantList none = engine->searchApps({QVariant::fromValue(weak.data()), QVariant::fromValue(strong.data())}, QStringLiteral("kotex"));
    QVERIFY2(none.isEmpty(), "an unreachable threshold must filter everything out");
}

void TestSearch::appSearchRecencyBreaksScoreTies() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            launched(new AppEntry(QStringLiteral("l.desktop"), QStringLiteral("Firefox"), {}, {}));
    QScopedPointer<AppEntry>            notLaunched(new AppEntry(QStringLiteral("n.desktop"), QStringLiteral("Firefox"), {}, {}));

    engine->recordLaunch(QStringLiteral("l.desktop"));

    const QVariantList result = engine->searchApps({QVariant::fromValue(notLaunched.data()), QVariant::fromValue(launched.data())}, QStringLiteral("firefox"));
    QVERIFY2(result.size() >= 2, "both identically-named apps must survive the threshold");
    QCOMPARE(result.first().value<QObject*>(), launched.data());
}

// A dropped character leaves the rest in order, so this matches by
// subsequence rather than by the edit-distance fallback.
void TestSearch::appSearchToleratesDroppedCharacter() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            firefox(new AppEntry(QStringLiteral("f.desktop"), QStringLiteral("Firefox"), {}, {}));
    QScopedPointer<AppEntry>            other(new AppEntry(QStringLiteral("o.desktop"), QStringLiteral("Thunderbird"), {}, {}));

    const QVariantList                  result = engine->searchApps({QVariant::fromValue(other.data()), QVariant::fromValue(firefox.data())}, QStringLiteral("firfox"));
    QVERIFY2(!result.isEmpty(), "a dropped character must still find the app");
    QCOMPARE(result.first().value<QObject*>(), firefox.data());
}

// The edit-distance fallback scores at most K_TYPO_FALLBACK_WEIGHT (0.5),
// while the floor is 0.45 per query character -- 3.15 here -- so a
// non-subsequence typo is never listed.
//
// The band pins the magnitude: "below the floor" alone would survive a
// tenfold cut in K_TYPO_FALLBACK_WEIGHT. Retuning that constant should mean
// updating this test deliberately.
void TestSearch::editDistanceFallbackStaysBelowAppThreshold() {
    const QString query = QStringLiteral("firefoz");
    const double  score = vast::FuzzyMatcher::fuzzyScore(query, QStringLiteral("firefox"));
    const double  floor = 0.45 * static_cast<double>(query.length());

    QVERIFY(!vast::fzy::hasMatch(query, QStringLiteral("firefox")));
    QVERIFY2(score > 0.3 && score < 0.5,
             qPrintable(QStringLiteral("edit-distance score is %1; the typo-fallback weight has been retuned and this "
                                       "test should be revisited")
                            .arg(score)));
    QVERIFY2(score < floor, "a non-subsequence typo must stay below the app threshold");
}

void TestSearch::appSearchIsDeterministic() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            a(new AppEntry(QStringLiteral("a.desktop"), QStringLiteral("Alpha"), {}, {}));
    QScopedPointer<AppEntry>            b(new AppEntry(QStringLiteral("b.desktop"), QStringLiteral("Alphabet"), {}, {}));
    QScopedPointer<AppEntry>            c(new AppEntry(QStringLiteral("c.desktop"), QStringLiteral("Alpine"), {}, {}));

    const QVariantList                  apps{QVariant::fromValue(a.data()), QVariant::fromValue(b.data()), QVariant::fromValue(c.data())};
    const QVariantList                  first  = engine->searchApps(apps, QStringLiteral("alp"));
    const QVariantList                  second = engine->searchApps(apps, QStringLiteral("alp"));

    QCOMPARE(first.size(), second.size());
    for (qsizetype i = 0; i < first.size(); ++i)
        QCOMPARE(first.at(i).value<QObject*>(), second.at(i).value<QObject*>());
}

void TestSearch::appCacheInvalidatesOnRename() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    // The cache keys on id and compares raw strings; a rename must be seen.
    RenameableEntry    entry(QStringLiteral("r.desktop"), QStringLiteral("Thunderbird"), QStringLiteral("Thunderbird"), QString());

    const QVariantList before = engine->searchApps({QVariant::fromValue(&entry)}, QStringLiteral("firefox"));
    QCOMPARE(before.size(), 0);

    entry.setName(QStringLiteral("Firefox"));
    const QVariantList after = engine->searchApps({QVariant::fromValue(&entry)}, QStringLiteral("firefox"));
    QVERIFY2(!after.isEmpty(), "a renamed app must be found under its new name");
}

void TestSearch::appCacheEvictsRemovedApps() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QScopedPointer<AppEntry>            kept(new AppEntry(QStringLiteral("k.desktop"), QStringLiteral("Firefox"), {}, {}));
    QScopedPointer<AppEntry>            dropped(new AppEntry(QStringLiteral("d.desktop"), QStringLiteral("Thunderbird"), {}, {}));

    engine->searchApps({QVariant::fromValue(kept.data()), QVariant::fromValue(dropped.data())}, QStringLiteral("fire"));
    // The dropped entry must not be resurrected by the cache.
    const QVariantList result = engine->searchApps({QVariant::fromValue(kept.data())}, QStringLiteral("fire"));
    QCOMPARE(result.size(), 1);
    QCOMPARE(result.first().value<QObject*>(), kept.data());
}

void TestSearch::fileSearchRanksMatchesByScore() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    const QVariantList                  files{
        fileEntry(QStringLiteral("main.cpp"), QStringLiteral("src/main.cpp")),
        fileEntry(QStringLiteral("other.txt"), QStringLiteral("docs/other.txt")),
        fileEntry(QStringLiteral("main.h"), QStringLiteral("src/main.h")),
    };

    engine->searchFilesAsync(files, QStringLiteral("main"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() > 0; }));

    auto* model = engine->fileResults();
    QVERIFY(model->rowCount() >= 2);
    // Both src/ entries outrank the docs/ one.
    QVERIFY(model->data(model->index(0, 0), static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)).toString().startsWith(QStringLiteral("src")));
    QVERIFY(model->data(model->index(1, 0), static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)).toString().startsWith(QStringLiteral("src")));
}

void TestSearch::fileSearchThresholdFiltersWeakMatches() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    const QVariantList                  files{
        fileEntry(QStringLiteral("main.cpp"), QStringLiteral("src/main.cpp")),
        fileEntry(QStringLiteral("readme.txt"), QStringLiteral("docs/readme.txt")),
    };

    engine->searchFilesAsync(files, QStringLiteral("main"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() > 0; }));
    QVERIFY(engine->fileResults()->rowCount() >= 1);

    engine->setFileThreshold(10.0);
    engine->searchFilesAsync(files, QStringLiteral("main"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 0; }));
}

void TestSearch::fileSearchEmptyQueryClearsResults() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    const QVariantList                  files{fileEntry(QStringLiteral("main.cpp"), QStringLiteral("src/main.cpp"))};

    engine->searchFilesAsync(files, QStringLiteral("main"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 1; }));

    engine->searchFilesAsync(files, QStringLiteral("   "));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 0; }));
}

void TestSearch::fileSearchIsPathAware() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    const QVariantList                  files{
        fileEntry(QStringLiteral("readme.txt"), QStringLiteral("src/config/readme.txt")),
        fileEntry(QStringLiteral("readme.txt"), QStringLiteral("other/readme.txt")),
    };

    // Lower the floor so both stay listed and the assertion is about order.
    engine->setFileThreshold(0.0);
    engine->searchFilesAsync(files, QStringLiteral("src readme"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 2; }));

    auto*         model  = engine->fileResults();
    const QString top    = model->data(model->index(0, 0), static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)).toString();
    const QString second = model->data(model->index(1, 0), static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)).toString();
    QCOMPARE(top, QStringLiteral("src/config/readme.txt"));
    QCOMPARE(second, QStringLiteral("other/readme.txt"));
}

void TestSearch::staleFileSearchIsDiscarded() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    const QVariantList                  narrow{fileEntry(QStringLiteral("target.cpp"), QStringLiteral("target.cpp"))};
    const QVariantList                  broad{
        fileEntry(QStringLiteral("target.cpp"), QStringLiteral("target.cpp")),
        fileEntry(QStringLiteral("other.cpp"), QStringLiteral("other.cpp")),
    };

    // Only the second generation may be applied.
    engine->searchFilesAsync(narrow, QStringLiteral("cpp"));
    engine->searchFilesAsync(broad, QStringLiteral("cpp"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 2; }));

    QTest::qWait(300);
    QCOMPARE(engine->fileResults()->rowCount(), 2);
}

void TestSearch::clearFileResultsEmptiesModel() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    engine->searchFilesAsync({fileEntry(QStringLiteral("a.cpp"), QStringLiteral("a.cpp"))}, QStringLiteral("a"));
    QVERIFY(spinUntil([&engine] { return engine->fileResults()->rowCount() == 1; }));

    engine->clearFileResults();
    QCOMPARE(engine->fileResults()->rowCount(), 0);
}

void TestSearch::thresholdSettersNotifyOnlyOnChange() {
    std::unique_ptr<vast::SearchEngine> engine(vast::SearchEngine::create(nullptr, nullptr));
    QSignalSpy                          appSpy(engine.get(), &vast::SearchEngine::appThresholdChanged);
    QSignalSpy                          fileSpy(engine.get(), &vast::SearchEngine::fileThresholdChanged);

    engine->setAppThreshold(engine->appThreshold());
    engine->setFileThreshold(engine->fileThreshold());
    QCOMPARE(appSpy.count(), 0);
    QCOMPARE(fileSpy.count(), 0);

    engine->setAppThreshold(engine->appThreshold() + 0.1);
    engine->setFileThreshold(engine->fileThreshold() + 0.1);
    QCOMPARE(appSpy.count(), 1);
    QCOMPARE(fileSpy.count(), 1);
}

void TestSearch::modelExposesFileListViewRoles() {
    vast::FileSearchModel model;
    // Role names are a contract with FileListView.
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::FileNameRole)), QByteArray("fileName"));
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::FilePathRole)), QByteArray("filePath"));
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)), QByteArray("relativePath"));
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::FileSizeRole)), QByteArray("fileSize"));
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::FileModifiedRole)), QByteArray("fileModified"));
    QCOMPARE(model.roleNames().value(static_cast<int>(vast::FileSearchModel::Roles::FileIsDirRole)), QByteArray("fileIsDir"));
}

void TestSearch::modelDataMatchesEntries() {
    vast::FileSearchModel model;
    model.setEntries({fileEntry(QStringLiteral("main.cpp"), QStringLiteral("src/main.cpp"), false)});
    QCOMPARE(model.rowCount(), 1);

    const QModelIndex index = model.index(0, 0);
    QCOMPARE(model.data(index, static_cast<int>(vast::FileSearchModel::Roles::FileNameRole)).toString(), QStringLiteral("main.cpp"));
    QCOMPARE(model.data(index, static_cast<int>(vast::FileSearchModel::Roles::RelativePathRole)).toString(), QStringLiteral("src/main.cpp"));
    QCOMPARE(model.data(index, static_cast<int>(vast::FileSearchModel::Roles::FileSizeRole)).toLongLong(), 42LL);
    QCOMPARE(model.data(index, static_cast<int>(vast::FileSearchModel::Roles::FileIsDirRole)).toBool(), false);
}

void TestSearch::modelResetEmitsModelReset() {
    vast::FileSearchModel model;
    QSignalSpy            spy(&model, &QAbstractItemModel::modelReset);

    model.setEntries({fileEntry(QStringLiteral("a"), QStringLiteral("a"))});
    QCOMPARE(spy.count(), 1);

    model.clear();
    QCOMPARE(spy.count(), 2);
    QCOMPARE(model.rowCount(), 0);
}

void TestSearch::modelRejectsOutOfRangeIndex() {
    vast::FileSearchModel model;
    model.setEntries({fileEntry(QStringLiteral("a"), QStringLiteral("a"))});
    // A stale index must return an invalid variant, not read past the end.
    QVERIFY(!model.data(model.index(5, 0), static_cast<int>(vast::FileSearchModel::Roles::FileNameRole)).isValid());
    QVERIFY(!model.data(QModelIndex(), static_cast<int>(vast::FileSearchModel::Roles::FileNameRole)).isValid());
    QCOMPARE(model.rowCount(model.index(0, 0)), 0);
}

void TestSearch::walkerCollectsFilesRecursively() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QVERIFY(QDir(root.path()).mkpath(QStringLiteral("a/b/c")));
    for (const QString& rel : {QStringLiteral("top.txt"), QStringLiteral("a/one.txt"), QStringLiteral("a/b/two.txt"), QStringLiteral("a/b/c/three.txt")}) {
        QFile file(QDir(root.path()).filePath(rel));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
    }

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    walker->setRoots({root.path()});
    walker->setMaxDepth(10);
    QSignalSpy finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));

    const QVariantList entries = finished.first().first().toList();
    QCOMPARE(countFiles(entries), 4);
    // Directories ride along as entries.
    QVERIFY(entries.size() > countFiles(entries));
    for (const QVariant& entry : entries) {
        const QString relativePath = entry.toMap().value(QStringLiteral("relativePath")).toString();
        QVERIFY2(!relativePath.isEmpty(), "every entry needs a relativePath; search scores on it");
        QVERIFY2(entry.toMap().contains(QStringLiteral("relativePathNorm")), "the walker must bake the normalized form; search falls back to per-keystroke encoding otherwise");
        QVERIFY2(entry.toMap().contains(QStringLiteral("relativePathUtf8")), "the walker must bake the UTF-8 form");
    }
}

void TestSearch::walkerRespectsMaxDepth() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QVERIFY(QDir(root.path()).mkpath(QStringLiteral("a/b/c")));
    for (const QString& rel : {QStringLiteral("top.txt"), QStringLiteral("a/one.txt"), QStringLiteral("a/b/two.txt"), QStringLiteral("a/b/c/three.txt")}) {
        QFile file(QDir(root.path()).filePath(rel));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
    }

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    walker->setRoots({root.path()});
    walker->setMaxDepth(1);
    QSignalSpy finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));
    QCOMPARE(countFiles(finished.first().first().toList()), 2);
}

void TestSearch::walkerSkipsHiddenByDefault() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QVERIFY(QDir(root.path()).mkpath(QStringLiteral(".hidden")));
    for (const QString& rel : {QStringLiteral("visible.txt"), QStringLiteral(".hidden/secret.txt"), QStringLiteral(".dotfile")}) {
        QFile file(QDir(root.path()).filePath(rel));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
    }

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    walker->setRoots({root.path()});
    QSignalSpy finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));
    QCOMPARE(countFiles(finished.first().first().toList()), 1);
}

void TestSearch::walkerIncludesHiddenWhenAsked() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QVERIFY(QDir(root.path()).mkpath(QStringLiteral(".hidden")));
    for (const QString& rel : {QStringLiteral("visible.txt"), QStringLiteral(".hidden/secret.txt")}) {
        QFile file(QDir(root.path()).filePath(rel));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
    }

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    walker->setRoots({root.path()});
    walker->setShowHidden(true);
    QSignalSpy finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));
    QCOMPARE(countFiles(finished.first().first().toList()), 2);
}

void TestSearch::walkerAppliesNameFilters() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QVERIFY(QDir(root.path()).mkpath(QStringLiteral("images")));
    for (const QString& rel : {QStringLiteral("a.png"), QStringLiteral("b.txt"), QStringLiteral("images/c.png")}) {
        QFile file(QDir(root.path()).filePath(rel));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
    }

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    walker->setRoots({root.path()});
    walker->setNameFilters({QStringLiteral("*.png")});
    QSignalSpy finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));
    QCOMPARE(countFiles(finished.first().first().toList()), 2);
}

void TestSearch::walkerIgnoresEmptyRoots() {
    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    QSignalSpy                            finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->requestWalk();
    // No roots means no walk at all.
    QTest::qWait(200);
    QCOMPARE(finished.count(), 0);
    QVERIFY(!walker->walking());
}

void TestSearch::walkingFlagTracksTheWalk() {
    QTemporaryDir root;
    QVERIFY(root.isValid());
    QFile file(QDir(root.path()).filePath(QStringLiteral("a.txt")));
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("x");

    QScopedPointer<vast::DirectoryWalker> walker(new vast::DirectoryWalker);
    QSignalSpy                            walkingSpy(walker.data(), &vast::DirectoryWalker::walkingChanged);
    QSignalSpy                            finished(walker.data(), &vast::DirectoryWalker::walkFinished);

    walker->setRoots({root.path()});
    QVERIFY(!walker->walking());

    walker->requestWalk();
    QVERIFY(spinUntil([&finished] { return finished.count() == 1; }));
    QVERIFY(!walker->walking());
    QVERIFY2(walkingSpy.count() >= 2, "the QML drawer binds to walkingChanged; it must fire on both edges");
}

QTEST_MAIN(TestSearch)
#include "tst_search.moc"
