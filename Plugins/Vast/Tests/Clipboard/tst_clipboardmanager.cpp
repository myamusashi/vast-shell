#include <qcryptographichash.h>
#include <qcoreapplication.h>
#include <qelapsedtimer.h>
#include <qeventloop.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qtemporarydir.h>
#include <qvariant.h>

#include "../../Clipboard/ClipboardDatabase.hpp"
#include "../../Clipboard/ClipboardEntry.hpp"
#include "../../Clipboard/ClipboardManager.hpp"

#include <memory>

namespace {

    constexpr int K_TIMEOUT_MS = 30000;

    // Ids of the three seeded entries.
    struct SSeeded {
        qint64 a;
        qint64 b;
        qint64 c;
    };

    template <typename Predicate>
    bool spinUntil(Predicate predicate) {
        QElapsedTimer timer;
        timer.start();
        while (!predicate() && timer.elapsed() < K_TIMEOUT_MS)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        return predicate();
    }

    // The manager's database is private, so seed the SQLite file first and let
    // initialize() load it through the normal path.
    qint64 seed(vast::ClipboardDatabase& db, const QString& content, qint64 timestamp, bool pinned = false) {
        vast::ClipboardEntry entry;
        entry.type      = vast::ClipboardType::Text;
        entry.content   = content;
        entry.mimeType  = QStringLiteral("text/plain;charset=utf-8");
        entry.hash      = QCryptographicHash::hash(content.toUtf8(), QCryptographicHash::Sha256);
        entry.pinned    = pinned;
        entry.sizeBytes = content.toUtf8().size();
        entry.timestamp = timestamp;
        const auto id   = db.insert(entry);
        return id.has_value() ? *id : -1;
    }

} // namespace

class TestClipboardManager : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void init();
    void cleanup();
    void cleanupTestCase();

    void initializePopulatesModel();
    void initializePutsPinnedFirst();
    void initializeFailsOnUnwritablePath();
    void copyToClipboardMovesEntryToTop();
    void copyToClipboardDebouncesRepeatCalls();
    void copyToClipboardUnknownIdFails();
    void removeUpdatesModelImmediatelyAndDatabaseAfterEventLoop();
    void removeManySkipsPinnedAndReturnsCount();
    void pinPersistsToDatabase();
    void clearUnpinnedKeepsPinned();
    void clearAllEmptiesModel();
    void setMaxEntriesPrunesModelAndDatabase();
    void requestFullEntryEmitsReadyForTextEntry();
    void requestFullEntryFailsForNegativeId();
    void requestFullEntryFailsForUnknownId();
    void propertySettersNotifyOnlyOnChange();

  private:
    // Fixed for the duration of one test: a fresh file each time, because
    // close() leaves the SQLite file behind and would carry rows across tests.
    [[nodiscard]] const QString& dbPath() const {
        return mDbPath;
    }

    std::unique_ptr<QTemporaryDir>          mDir;
    std::unique_ptr<vast::ClipboardManager> mManager;
    QString                                 mDbPath;
    int                                     mSeq{0};

    // Populates the DB file with three unpinned entries at 1000/2000/3000.
    [[nodiscard]] SSeeded seedThreeUnpinned();
};

void TestClipboardManager::initTestCase() {
    mDir = std::make_unique<QTemporaryDir>();
    QVERIFY(mDir->isValid());
}

void TestClipboardManager::init() {
    mManager.reset();
    mDbPath = mDir->path() + QStringLiteral("/clipboard-%1.db").arg(mSeq++);
}

void TestClipboardManager::cleanup() {
    mManager.reset();
}

void TestClipboardManager::cleanupTestCase() {
    mManager.reset();
}

// QVERIFY expands to a bare `return`, so it cannot appear in a non-void
// function; return a sentinel the caller checks instead.
SSeeded TestClipboardManager::seedThreeUnpinned() {
    vast::ClipboardDatabase db;
    const auto              opened = db.open(dbPath());
    if (!opened.has_value()) {
        qWarning("seed failed to open: %s", qPrintable(opened.error()));
        return {};
    }

    const SSeeded ids{seed(db, QStringLiteral("alpha"), 1000), seed(db, QStringLiteral("beta"), 2000), seed(db, QStringLiteral("gamma"), 3000)};
    db.close();
    return ids;
}

void TestClipboardManager::initializePopulatesModel() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->rowCount(), 3);
    QCOMPARE(mManager->model()->idAtRow(0), ids.c);
    QCOMPARE(mManager->model()->idAtRow(2), ids.a);
}

void TestClipboardManager::initializePutsPinnedFirst() {
    vast::ClipboardDatabase db;
    QVERIFY(db.open(dbPath()).has_value());
    const qint64 pinnedId = seed(db, QStringLiteral("pinned-old"), 500, true);
    seed(db, QStringLiteral("newer"), 2000);
    db.close();

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QVERIFY(pinnedId > 0);
    QCOMPARE(mManager->model()->idAtRow(0), pinnedId);
    QCOMPARE(mManager->model()->rowCount(), 2);
}

void TestClipboardManager::initializeFailsOnUnwritablePath() {
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(!mManager->initialize(QStringLiteral("/nonexistent-dir-xyz/clipboard.db")));
}

void TestClipboardManager::copyToClipboardMovesEntryToTop() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->idAtRow(2), ids.a);

    QVERIFY(mManager->copyToClipboard(ids.a));
    QCOMPARE(mManager->model()->idAtRow(0), ids.a);
}

void TestClipboardManager::copyToClipboardDebouncesRepeatCalls() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QVERIFY(mManager->copyToClipboard(ids.a));
    QCOMPARE(mManager->model()->idAtRow(0), ids.a);

    // Within the 500 ms window the repeat is swallowed, so the entry that is now
    // second must not be pulled back to the top.
    QVERIFY(mManager->copyToClipboard(ids.a));
    QCOMPARE(mManager->model()->idAtRow(0), ids.a);
    QCOMPARE(mManager->model()->idAtRow(1), ids.c);

    // Move the target down, then wait out the window and copy again.
    QVERIFY(mManager->copyToClipboard(ids.b));
    QTest::qWait(600);
    QVERIFY(mManager->copyToClipboard(ids.a));
    QCOMPARE(mManager->model()->idAtRow(0), ids.a);
}

void TestClipboardManager::copyToClipboardUnknownIdFails() {
    seedThreeUnpinned();
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QVERIFY(!mManager->copyToClipboard(999999));
}

void TestClipboardManager::removeUpdatesModelImmediatelyAndDatabaseAfterEventLoop() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->rowCount(), 3);

    mManager->remove(ids.b);
    QCOMPARE(mManager->model()->rowCount(), 2);

    // remove() defers the DELETE through QTimer::singleShot(0), so poll the
    // database itself rather than the model.
    QVERIFY(spinUntil([this, ids] {
        vast::ClipboardDatabase db;
        if (!db.open(dbPath()).has_value())
            return false;
        const bool gone = !db.fetchById(ids.b).has_value();
        db.close();
        return gone;
    }));

    vast::ClipboardDatabase db;
    QVERIFY(db.open(dbPath()).has_value());
    QVERIFY(!db.fetchById(ids.b).has_value());
    QVERIFY(db.fetchById(ids.a).has_value());
    db.close();
}

void TestClipboardManager::removeManySkipsPinnedAndReturnsCount() {
    vast::ClipboardDatabase db;
    QVERIFY(db.open(dbPath()).has_value());
    const qint64 a = seed(db, QStringLiteral("a"), 1000);
    const qint64 b = seed(db, QStringLiteral("b"), 2000);
    const qint64 c = seed(db, QStringLiteral("c"), 3000, true);
    db.close();

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->removeMany({a, b, c}), 2);
    QCOMPARE(mManager->model()->rowCount(), 1);
    QCOMPARE(mManager->model()->idAtRow(0), c);
}

void TestClipboardManager::pinPersistsToDatabase() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QVERIFY(mManager->model()->idAtRow(0) != ids.a);

    mManager->pin(ids.a, true);
    QCOMPARE(mManager->model()->idAtRow(0), ids.a);

    // pin() defers the UPDATE through QTimer::singleShot(0).
    QVERIFY(spinUntil([this, ids] {
        vast::ClipboardDatabase db;
        if (!db.open(dbPath()).has_value())
            return false;
        const auto fetched = db.fetchById(ids.a);
        db.close();
        return fetched.has_value() && fetched->pinned;
    }));
}

void TestClipboardManager::clearUnpinnedKeepsPinned() {
    vast::ClipboardDatabase db;
    QVERIFY(db.open(dbPath()).has_value());
    const qint64 pinnedId = seed(db, QStringLiteral("keep"), 1000, true);
    seed(db, QStringLiteral("drop-a"), 2000);
    seed(db, QStringLiteral("drop-b"), 3000);
    db.close();

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->rowCount(), 3);

    QVERIFY(mManager->clearUnpinned());
    QVERIFY(spinUntil([this] { return mManager->model()->rowCount() == 1; }));
    QCOMPARE(mManager->model()->idAtRow(0), pinnedId);
}

void TestClipboardManager::clearAllEmptiesModel() {
    seedThreeUnpinned();
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->rowCount(), 3);

    QVERIFY(mManager->clearAll());
    QVERIFY(spinUntil([this] { return mManager->model()->rowCount() == 0; }));
}

void TestClipboardManager::setMaxEntriesPrunesModelAndDatabase() {
    vast::ClipboardDatabase db;
    QVERIFY(db.open(dbPath()).has_value());
    seed(db, QStringLiteral("t1000"), 1000);
    seed(db, QStringLiteral("t2000"), 2000);
    seed(db, QStringLiteral("t3000"), 3000);
    seed(db, QStringLiteral("t4000"), 4000);
    db.close();

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));
    QCOMPARE(mManager->model()->rowCount(), 4);

    mManager->setMaxEntries(2);
    QCOMPARE(mManager->model()->rowCount(), 2);

    vast::ClipboardDatabase check;
    QVERIFY(check.open(dbPath()).has_value());
    QCOMPARE(check.fetchAll()->size(), 2);
    check.close();
}

void TestClipboardManager::requestFullEntryEmitsReadyForTextEntry() {
    const SSeeded ids = seedThreeUnpinned();
    QVERIFY2(ids.a > 0 && ids.b > 0 && ids.c > 0, "seeding failed");

    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QSignalSpy ready(mManager.get(), &vast::ClipboardManager::fullEntryReady);
    mManager->requestFullEntry(ids.b);

    QVERIFY(spinUntil([&ready] { return ready.count() == 1; }));
    const QVariantMap map = ready.first().first().toMap();
    QCOMPARE(map.value(QStringLiteral("content")).toString(), QStringLiteral("beta"));
    QCOMPARE(map.value(QStringLiteral("id")).toLongLong(), ids.b);
}

void TestClipboardManager::requestFullEntryFailsForNegativeId() {
    seedThreeUnpinned();
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QSignalSpy failed(mManager.get(), &vast::ClipboardManager::fullEntryFailed);
    mManager->requestFullEntry(-1);
    QCOMPARE(failed.count(), 1);
    QCOMPARE(failed.first().first().toLongLong(), -1);
}

void TestClipboardManager::requestFullEntryFailsForUnknownId() {
    seedThreeUnpinned();
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QSignalSpy ready(mManager.get(), &vast::ClipboardManager::fullEntryReady);
    QSignalSpy failed(mManager.get(), &vast::ClipboardManager::fullEntryFailed);
    mManager->requestFullEntry(999999);

    QVERIFY(spinUntil([&failed] { return failed.count() == 1; }));
    QCOMPARE(ready.count(), 0);
}

void TestClipboardManager::propertySettersNotifyOnlyOnChange() {
    seedThreeUnpinned();
    mManager = std::make_unique<vast::ClipboardManager>();
    QVERIFY(mManager->initialize(dbPath()));

    QSignalSpy maxEntries(mManager.get(), &vast::ClipboardManager::maxEntriesChanged);
    QSignalSpy maxMegabytes(mManager.get(), &vast::ClipboardManager::maxMegabytesChanged);
    QSignalSpy enabled(mManager.get(), &vast::ClipboardManager::enabledChanged);
    QSignalSpy activeWindow(mManager.get(), &vast::ClipboardManager::activeWindowChanged);

    mManager->setMaxEntries(mManager->maxEntries());
    mManager->setMaxMegabytes(mManager->maxMegabytes());
    mManager->setEnabled(mManager->isEnabled());
    mManager->setActiveWindow(mManager->activeWindow());
    QCOMPARE(maxEntries.count(), 0);
    QCOMPARE(maxMegabytes.count(), 0);
    QCOMPARE(enabled.count(), 0);
    QCOMPARE(activeWindow.count(), 0);

    mManager->setMaxEntries(mManager->maxEntries() + 1);
    mManager->setMaxMegabytes(mManager->maxMegabytes() + 1);
    mManager->setEnabled(!mManager->isEnabled());
    mManager->setActiveWindow(QStringLiteral("org.example.Window"));
    QCOMPARE(maxEntries.count(), 1);
    QCOMPARE(maxMegabytes.count(), 1);
    QCOMPARE(enabled.count(), 1);
    QCOMPARE(activeWindow.count(), 1);
}

QTEST_MAIN(TestClipboardManager)
#include "tst_clipboardmanager.moc"
