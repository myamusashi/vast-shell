#include <qcryptographichash.h>
#include <qlist.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtemporarydir.h>
#include <qtest.h>

#include "../../Clipboard/ClipboardDatabase.hpp"
#include "../../Clipboard/ClipboardEntry.hpp"

#include <memory>
#include <vector>

// Every method returns std::expected, so tests assert has_value() and read *result.
namespace {

    vast::ClipboardEntry makeEntry(const QByteArray& content, vast::ClipboardType type = vast::ClipboardType::Text, bool pinned = false, qint64 timestamp = 0) {
        vast::ClipboardEntry entry;
        entry.type      = type;
        entry.content   = type == vast::ClipboardType::Image ? QString{} : QString::fromUtf8(content);
        entry.data      = type == vast::ClipboardType::Image ? content : QByteArray{};
        entry.mimeType  = type == vast::ClipboardType::Image ? QStringLiteral("image/png") : QStringLiteral("text/plain;charset=utf-8");
        entry.hash      = QCryptographicHash::hash(content, QCryptographicHash::Sha256);
        entry.pinned    = pinned;
        entry.sizeBytes = content.size();
        entry.timestamp = timestamp;
        return entry;
    }

} // namespace

class TestClipboardDatabase : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void init();
    void cleanup();

    void openAndSchema();
    void closedDatabaseRejectsEveryCall();
    void insertAssignsIncreasingIds();
    void insertEmitsEntryWithIdAndNoData();
    void insertRejectsDuplicateHash();
    void insertDefaultsZeroTimestamp();
    void imageDataRoundTripsOnlyViaFetchById();
    void removeDeletesOnlyTheGivenId();
    void removeManySkipsPinnedByDefault();
    void removeManyWithSkipPinnedFalseRemovesAll();
    void removeManyEmptyListReturnsZero();
    void setPinRoundTrips();
    void bumpTimestampAdvances();
    void pruneToEntriesLimitRemovesOldestUnpinnedFirst();
    void pruneToBytesLimitRemovesUntilUnderLimit();
    void pruneToLimitNoopWhenUnderBothLimits();
    void fetchAllOrdersPinnedFirstThenNewest();
    void fetchByIdMissingErrors();
    void fetchIdByHash();
    void existsByHashReflectsInsertAndRemove();
    void closeIsIdempotentAndReportsClosed();

  private:
    // A fresh file per test: close() leaves the SQLite file on disk, so
    // sharing one path would leak rows between tests.
    [[nodiscard]] QString dbPath() {
        return mDir->path() + QStringLiteral("/clipboard-%1.db").arg(mSeq++);
    }

    std::unique_ptr<QTemporaryDir> mDir;
    vast::ClipboardDatabase        mDb;
    int                            mSeq{0};
};

void TestClipboardDatabase::initTestCase() {
    mDir = std::make_unique<QTemporaryDir>();
    QVERIFY(mDir->isValid());
}

void TestClipboardDatabase::init() {
    // std::expected::error() is undefined when the value is held, and QVERIFY2
    // evaluates its message eagerly, so branch before touching error().
    const auto opened = mDb.open(dbPath());
    if (!opened.has_value())
        QFAIL(qPrintable(opened.error()));
}

void TestClipboardDatabase::cleanup() {
    mDb.close();
}

void TestClipboardDatabase::openAndSchema() {
    QVERIFY(mDb.isOpen());

    const auto again = mDb.open(dbPath() + QStringLiteral("-other"));
    QVERIFY(!again.has_value());
    QCOMPARE(again.error(), QStringLiteral("Database already open"));
}

void TestClipboardDatabase::closedDatabaseRejectsEveryCall() {
    vast::ClipboardDatabase closed;
    QVERIFY(!closed.isOpen());

    const QList<qint64>        ids{1};
    const vast::ClipboardEntry entry = makeEntry("x");

    const auto                 expectNotOpen = [](const auto& result) { return !result.has_value() && result.error().contains(QStringLiteral("Database is not open")); };

    QVERIFY(expectNotOpen(closed.bumpTimestamp(1)));
    QVERIFY(expectNotOpen(closed.clearAll()));
    QVERIFY(expectNotOpen(closed.clearUnpinned()));
    QVERIFY(expectNotOpen(closed.pruneToLimit(1, 1)));
    QVERIFY(expectNotOpen(closed.fetchIdByHash(entry.hash)));
    QVERIFY(expectNotOpen(closed.fetchAll()));
    QVERIFY(expectNotOpen(closed.fetchById(1)));
    QVERIFY(expectNotOpen(closed.totalSizeBytes()));
    QVERIFY(!closed.existsByHash(entry.hash));
}

void TestClipboardDatabase::insertAssignsIncreasingIds() {
    const auto first  = mDb.insert(makeEntry("one"));
    const auto second = mDb.insert(makeEntry("two"));
    const auto third  = mDb.insert(makeEntry("three"));

    QVERIFY(first.has_value());
    QVERIFY(second.has_value());
    QVERIFY(third.has_value());
    QCOMPARE(*first, 1);
    QCOMPARE(*second, 2);
    QCOMPARE(*third, 3);
}

void TestClipboardDatabase::insertEmitsEntryWithIdAndNoData() {
    QSignalSpy spy(&mDb, &vast::ClipboardDatabase::entryInserted);

    const auto image = makeEntry(QByteArray("\x89PNG-bytes", 11), vast::ClipboardType::Image);
    const auto id    = mDb.insert(image);
    QVERIFY(id.has_value());
    QCOMPARE(spy.count(), 1);

    const auto emitted = spy.first().first().value<vast::ClipboardEntry>();
    QCOMPARE(emitted.id, *id);
    QVERIFY(emitted.data.isEmpty());
}

void TestClipboardDatabase::insertRejectsDuplicateHash() {
    const auto first = mDb.insert(makeEntry("same"));
    QVERIFY(first.has_value());

    const auto second = mDb.insert(makeEntry("same"));
    QVERIFY(!second.has_value());
    QCOMPARE(second.error(), QStringLiteral("duplicate"));

    const auto all = mDb.fetchAll();
    QVERIFY(all.has_value());
    QCOMPARE(all->size(), 1);
}

void TestClipboardDatabase::insertDefaultsZeroTimestamp() {
    const auto id = mDb.insert(makeEntry("timestamped", vast::ClipboardType::Text, false, 0));
    QVERIFY(id.has_value());

    const auto fetched = mDb.fetchById(*id);
    QVERIFY(fetched.has_value());
    QVERIFY2(fetched->timestamp > 0, "a zero timestamp must be replaced with the current time");
}

void TestClipboardDatabase::imageDataRoundTripsOnlyViaFetchById() {
    const QByteArray bytes("\x89PNG\x0d\x0a-pretend", 15);
    const auto       id = mDb.insert(makeEntry(bytes, vast::ClipboardType::Image));
    QVERIFY(id.has_value());

    const auto byId = mDb.fetchById(*id);
    QVERIFY(byId.has_value());
    QCOMPARE(byId->data, bytes);

    // fetchAll omits the blob so listing the history stays cheap.
    const auto all = mDb.fetchAll();
    QVERIFY(all.has_value());
    QCOMPARE(all->first().data, QByteArray{});
    QVERIFY(all->first().content.isEmpty());
}

void TestClipboardDatabase::removeDeletesOnlyTheGivenId() {
    const auto first  = mDb.insert(makeEntry("first"));
    const auto second = mDb.insert(makeEntry("second"));
    QVERIFY(first.has_value() && second.has_value());

    QSignalSpy spy(&mDb, &vast::ClipboardDatabase::entryRemoved);
    const auto removed = mDb.remove(*first);
    QVERIFY(removed.has_value());

    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.first().first().toLongLong(), *first);
    QVERIFY(!mDb.fetchById(*first).has_value());
    QVERIFY(mDb.fetchById(*second).has_value());
}

void TestClipboardDatabase::removeManySkipsPinnedByDefault() {
    const auto a = mDb.insert(makeEntry("a"));
    const auto b = mDb.insert(makeEntry("b"));
    const auto c = mDb.insert(makeEntry("c", vast::ClipboardType::Text, true));
    QVERIFY(a.has_value() && b.has_value() && c.has_value());

    QSignalSpy          spy(&mDb, &vast::ClipboardDatabase::entryRemoved);
    const QList<qint64> ids{*a, *b, *c};
    const auto          removed = mDb.removeMany(ids);
    QVERIFY(removed.has_value());
    QCOMPARE(*removed, 2);

    // The implementation emits once per requested id, not per deleted row.
    QCOMPARE(spy.count(), 3);

    QVERIFY(!mDb.fetchById(*a).has_value());
    QVERIFY(!mDb.fetchById(*b).has_value());
    QVERIFY2(mDb.fetchById(*c).has_value(), "a pinned entry must survive removeMany");
}

void TestClipboardDatabase::removeManyWithSkipPinnedFalseRemovesAll() {
    const auto a = mDb.insert(makeEntry("a"));
    const auto b = mDb.insert(makeEntry("b", vast::ClipboardType::Text, true));
    QVERIFY(a.has_value() && b.has_value());

    const QList<qint64> ids{*a, *b};
    const auto          removed = mDb.removeMany(ids, false);
    QVERIFY(removed.has_value());
    QCOMPARE(*removed, 2);

    const auto all = mDb.fetchAll();
    QVERIFY(all.has_value());
    QVERIFY(all->isEmpty());
}

void TestClipboardDatabase::removeManyEmptyListReturnsZero() {
    const auto removed = mDb.removeMany({});
    QVERIFY(removed.has_value());
    QCOMPARE(*removed, 0);
}

void TestClipboardDatabase::setPinRoundTrips() {
    const auto id = mDb.insert(makeEntry("pinme"));
    QVERIFY(id.has_value());

    QSignalSpy spy(&mDb, &vast::ClipboardDatabase::entryPinChanged);
    const auto pinned = mDb.setPin(*id, true);
    QVERIFY(pinned.has_value());
    QCOMPARE(spy.count(), 1);
    QCOMPARE(spy.first().first().toLongLong(), *id);
    QCOMPARE(spy.first().at(1).toBool(), true);

    QVERIFY(mDb.fetchById(*id)->pinned);

    QVERIFY(mDb.setPin(*id, false).has_value());
    QVERIFY(!mDb.fetchById(*id)->pinned);
}

void TestClipboardDatabase::bumpTimestampAdvances() {
    const auto id = mDb.insert(makeEntry("bump", vast::ClipboardType::Text, false, 1000));
    QVERIFY(id.has_value());

    QVERIFY(mDb.bumpTimestamp(*id).has_value());
    QVERIFY2(mDb.fetchById(*id)->timestamp > 1000, "bumpTimestamp must move the entry to now");
}

void TestClipboardDatabase::pruneToEntriesLimitRemovesOldestUnpinnedFirst() {
    const auto oldest = mDb.insert(makeEntry("ts1000", vast::ClipboardType::Text, true, 1000));
    const auto second = mDb.insert(makeEntry("ts2000", vast::ClipboardType::Text, false, 2000));
    const auto third  = mDb.insert(makeEntry("ts3000", vast::ClipboardType::Text, false, 3000));
    const auto newest = mDb.insert(makeEntry("ts4000", vast::ClipboardType::Text, false, 4000));
    QVERIFY(oldest.has_value() && second.has_value() && third.has_value() && newest.has_value());

    // The limit counts unpinned rows only: 3 unpinned against a limit of 2 is an
    // excess of 1, and the oldest unpinned row is the one that goes.
    const auto pruned = mDb.pruneToLimit(2, 0);
    QVERIFY(pruned.has_value());
    QCOMPARE(pruned->size(), std::size_t{1});
    QCOMPARE(pruned->front(), *second);

    const auto all = mDb.fetchAll();
    QVERIFY(all.has_value());
    QCOMPARE(all->size(), 3);
    // fetchAll sorts pinned first, then newest first.
    QCOMPARE(all->at(0).id, *oldest);
    QCOMPARE(all->at(1).id, *newest);
    QCOMPARE(all->at(2).id, *third);
}

void TestClipboardDatabase::pruneToBytesLimitRemovesUntilUnderLimit() {
    // Four 100-byte entries: 400 total, limit 250, so the oldest two must go.
    for (int i = 0; i < 4; ++i)
        QVERIFY(mDb.insert(makeEntry(QByteArray(100, 'a' + i), vast::ClipboardType::Text, false, 1000 + i)).has_value());

    const qint64 before = *mDb.totalSizeBytes();
    QCOMPARE(before, 400);

    const auto pruned = mDb.pruneToLimit(0, 250);
    QVERIFY(pruned.has_value());
    QCOMPARE(pruned->size(), std::size_t{2});
    QVERIFY2(*mDb.totalSizeBytes() <= 250, "the byte limit must be respected after pruning");
}

void TestClipboardDatabase::pruneToLimitNoopWhenUnderBothLimits() {
    QVERIFY(mDb.insert(makeEntry("small")).has_value());

    const auto pruned = mDb.pruneToLimit(100, 1LL << 30);
    QVERIFY(pruned.has_value());
    QVERIFY(pruned->empty());
    QCOMPARE(mDb.fetchAll()->size(), 1);
}

void TestClipboardDatabase::fetchAllOrdersPinnedFirstThenNewest() {
    QVERIFY(mDb.insert(makeEntry("u1000", vast::ClipboardType::Text, false, 1000)).has_value());
    QVERIFY(mDb.insert(makeEntry("u2000", vast::ClipboardType::Text, false, 2000)).has_value());
    QVERIFY(mDb.insert(makeEntry("u3000", vast::ClipboardType::Text, false, 3000)).has_value());
    QVERIFY(mDb.insert(makeEntry("p500", vast::ClipboardType::Text, true, 500)).has_value());

    const auto all = mDb.fetchAll();
    QVERIFY(all.has_value());
    QCOMPARE(all->size(), 4);
    QVERIFY(all->at(0).pinned);
    QCOMPARE(all->at(0).content, QStringLiteral("p500"));
    QCOMPARE(all->at(1).content, QStringLiteral("u3000"));
    QCOMPARE(all->at(2).content, QStringLiteral("u2000"));
    QCOMPARE(all->at(3).content, QStringLiteral("u1000"));
}

void TestClipboardDatabase::fetchByIdMissingErrors() {
    const auto fetched = mDb.fetchById(9999);
    QVERIFY(!fetched.has_value());
    QVERIFY(fetched.error().contains(QStringLiteral("No entry found with id")));
}

void TestClipboardDatabase::fetchIdByHash() {
    const vast::ClipboardEntry entry = makeEntry("findable");
    const auto                 id    = mDb.insert(entry);
    QVERIFY(id.has_value());

    const auto found = mDb.fetchIdByHash(entry.hash);
    QVERIFY(found.has_value());
    QCOMPARE(*found, *id);

    const auto missing = mDb.fetchIdByHash(QByteArray("no-such-hash"));
    QVERIFY(!missing.has_value());
    QVERIFY(missing.error().contains(QStringLiteral("No entry found for hash")));
}

void TestClipboardDatabase::existsByHashReflectsInsertAndRemove() {
    const vast::ClipboardEntry entry = makeEntry("exists");
    QVERIFY(!mDb.existsByHash(entry.hash));

    const auto id = mDb.insert(entry);
    QVERIFY(id.has_value());
    QVERIFY(mDb.existsByHash(entry.hash));

    QVERIFY(mDb.remove(*id).has_value());
    QVERIFY(!mDb.existsByHash(entry.hash));
}

void TestClipboardDatabase::closeIsIdempotentAndReportsClosed() {
    QVERIFY(mDb.isOpen());
    mDb.close();
    QVERIFY(!mDb.isOpen());
    mDb.close();
    QVERIFY(!mDb.isOpen());
}

QTEST_MAIN(TestClipboardDatabase)
#include "tst_clipboarddatabase.moc"
