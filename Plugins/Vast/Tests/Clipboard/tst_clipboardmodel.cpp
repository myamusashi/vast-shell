#include <qabstractitemmodel.h>
#include <qlist.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include "../../Clipboard/ClipboardEntry.hpp"
#include "../../Clipboard/ClipboardModel.hpp"

namespace {

    vast::ClipboardEntry entry(qint64 id, const QString& content, qint64 timestamp, bool pinned = false, vast::ClipboardType type = vast::ClipboardType::Text) {
        vast::ClipboardEntry e;
        e.id        = id;
        e.type      = type;
        e.content   = type == vast::ClipboardType::Image ? QString{} : content;
        e.timestamp = timestamp;
        e.pinned    = pinned;
        e.sourceApp = QStringLiteral("testapp");
        e.mimeType  = QStringLiteral("text/plain;charset=utf-8");
        e.sizeBytes = content.toUtf8().size();
        return e;
    }

    QList<qint64> visibleIds(const vast::ClipboardModel& model) {
        QList<qint64> ids;
        for (int row = 0; row < model.rowCount(); ++row)
            ids.append(model.idAtRow(row));
        return ids;
    }

} // namespace

class TestClipboardModel : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void roleNamesMatchQmlContract();
    void dataRejectsOutOfRangeIndex();
    void fileNameRoleReturnsBasenameOnly();
    void previewRoleEmptyForImages();
    void previewRoleTruncatesAt120Chars();
    void resetReplacesEntriesAndClearsFilter();
    void prependInsertsNewestFirst();
    void prependPlacesPinnedAboveUnpinned();
    void prependExistingIdUpdatesTimestampInPlace();
    void removeByIdRemovesOnlyThatRow();
    void removeByIdsRemovesTheGivenSet();
    void setPinByIdResortsPinnedFirst();
    void setFilterNarrowsToFuzzyMatches();
    void setFilterPutsPinnedFirstAmongMatches();
    void setFilterEmptyQueryRestoresEverything();
    void setFilterExcludesNonMatches();
    void bumpToTopMovesToFront();
    void bumpToTopUnknownIdIsNoop();
    void idAtRowAndTypeAtRowRejectOutOfRange();
    void entriesExposesEveryField();
    void countChangedFiresOnMutation();
};

void TestClipboardModel::roleNamesMatchQmlContract() {
    vast::ClipboardModel model;
    using Roles = vast::ClipboardModel::Roles;

    const QHash<int, QByteArray> names = model.roleNames();
    QCOMPARE(names.value(static_cast<int>(Roles::IdRole)), QByteArray("entryId"));
    QCOMPARE(names.value(static_cast<int>(Roles::TypeRole)), QByteArray("type"));
    QCOMPARE(names.value(static_cast<int>(Roles::PreviewRole)), QByteArray("preview"));
    QCOMPARE(names.value(static_cast<int>(Roles::TimestampRole)), QByteArray("timestamp"));
    QCOMPARE(names.value(static_cast<int>(Roles::PinnedRole)), QByteArray("pinned"));
    QCOMPARE(names.value(static_cast<int>(Roles::SourceAppRole)), QByteArray("sourceApp"));
    QCOMPARE(names.value(static_cast<int>(Roles::MimeTypeRole)), QByteArray("mimeType"));
    QCOMPARE(names.value(static_cast<int>(Roles::SizeBytesRole)), QByteArray("sizeBytes"));
    QCOMPARE(names.value(static_cast<int>(Roles::FileNameRole)), QByteArray("fileName"));
    QCOMPARE(names.size(), 9);
}

void TestClipboardModel::dataRejectsOutOfRangeIndex() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("one"), 1000)});
    using Roles = vast::ClipboardModel::Roles;

    QVERIFY(!model.data(model.index(5, 0), static_cast<int>(Roles::IdRole)).isValid());
    QVERIFY(!model.data(QModelIndex(), static_cast<int>(Roles::IdRole)).isValid());
    QCOMPARE(model.rowCount(model.index(0, 0)), 0);
}

void TestClipboardModel::fileNameRoleReturnsBasenameOnly() {
    vast::ClipboardModel model;
    vast::ClipboardEntry e = entry(1, QStringLiteral("x"), 1000);
    e.fileName             = QStringLiteral("/tmp/dir/report.pdf");
    model.reset({e});

    using Roles = vast::ClipboardModel::Roles;
    QCOMPARE(model.data(model.index(0, 0), static_cast<int>(Roles::FileNameRole)).toString(), QStringLiteral("report.pdf"));
}

void TestClipboardModel::previewRoleEmptyForImages() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("ignored"), 1000, false, vast::ClipboardType::Image)});

    using Roles = vast::ClipboardModel::Roles;
    QVERIFY(model.data(model.index(0, 0), static_cast<int>(Roles::PreviewRole)).toString().isEmpty());
}

void TestClipboardModel::previewRoleTruncatesAt120Chars() {
    vast::ClipboardModel model;
    model.reset({entry(1, QString(200, QLatin1Char('x')), 1000)});

    using Roles           = vast::ClipboardModel::Roles;
    const QString preview = model.data(model.index(0, 0), static_cast<int>(Roles::PreviewRole)).toString();
    QCOMPARE(preview.length(), 121);
    QVERIFY(preview.endsWith(QChar(0x2026)));
}

void TestClipboardModel::resetReplacesEntriesAndClearsFilter() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("alpha"), 1000), entry(2, QStringLiteral("beta"), 2000), entry(3, QStringLiteral("gamma"), 3000)});
    model.setFilter(QStringLiteral("a"));
    QVERIFY(model.rowCount() < 3);

    // reset() stores the list verbatim; it does not re-sort.
    model.reset({entry(4, QStringLiteral("delta"), 4000), entry(5, QStringLiteral("epsilon"), 5000)});
    QCOMPARE(model.rowCount(), 2);
    QCOMPARE(model.idAtRow(0), 4);
    QCOMPARE(model.idAtRow(1), 5);
}

void TestClipboardModel::prependInsertsNewestFirst() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 1000), entry(2, QStringLiteral("b"), 2000)});

    model.prepend(entry(3, QStringLiteral("c"), 3000));
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.idAtRow(0), 3);
}

void TestClipboardModel::prependPlacesPinnedAboveUnpinned() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 1000), entry(2, QStringLiteral("b"), 2000)});

    // Older than both, but pinned, so it must still sort first.
    model.prepend(entry(3, QStringLiteral("c"), 500, true));
    QCOMPARE(model.idAtRow(0), 3);
}

void TestClipboardModel::prependExistingIdUpdatesTimestampInPlace() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000), entry(3, QStringLiteral("c"), 1000)});

    model.prepend(entry(3, QStringLiteral("c"), 4000));
    QCOMPARE(model.rowCount(), 3);
    QCOMPARE(model.idAtRow(0), 3);
    QCOMPARE(visibleIds(model), (QList<qint64>{3, 1, 2}));
}

void TestClipboardModel::removeByIdRemovesOnlyThatRow() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000), entry(3, QStringLiteral("c"), 1000)});

    model.removeById(2);
    QCOMPARE(visibleIds(model), (QList<qint64>{1, 3}));

    model.removeById(9999);
    QCOMPARE(visibleIds(model), (QList<qint64>{1, 3}));
}

void TestClipboardModel::removeByIdsRemovesTheGivenSet() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000), entry(3, QStringLiteral("c"), 1000)});

    model.removeByIds({1, 3});
    QCOMPARE(visibleIds(model), (QList<qint64>{2}));

    model.removeByIds({});
    QCOMPARE(visibleIds(model), (QList<qint64>{2}));
}

void TestClipboardModel::setPinByIdResortsPinnedFirst() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000), entry(3, QStringLiteral("c"), 1000)});

    model.setPinById(3, true);
    QCOMPARE(model.idAtRow(0), 3);

    model.setPinById(3, false);
    QCOMPARE(model.idAtRow(0), 1);
}

void TestClipboardModel::setFilterNarrowsToFuzzyMatches() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("Firefox"), 1000), entry(2, QStringLiteral("Thunderbird"), 2000), entry(3, QStringLiteral("GIMP"), 3000)});

    model.setFilter(QStringLiteral("fire"));
    QCOMPARE(visibleIds(model), (QList<qint64>{1}));
}

// Regression guard for the pinned-first ordering under an active filter.
// ClipboardModel::rebuildFilter used to return `b.pinned` when pin states
// differed, which inverted the branch and sank pinned rows to the bottom of a
// filtered list — inconsistent with fetchAll's `ORDER BY pinned DESC`,
// setPinById, and prepend. Fixed in ClipboardModel.cpp.
void TestClipboardModel::setFilterPutsPinnedFirstAmongMatches() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("firefox browser"), 3000), entry(2, QStringLiteral("firefox nightly"), 2000, true)});

    model.setFilter(QStringLiteral("firefox"));
    QVERIFY(model.rowCount() >= 2);
    QCOMPARE(model.idAtRow(0), 2);
}

void TestClipboardModel::setFilterEmptyQueryRestoresEverything() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("Firefox"), 1000), entry(2, QStringLiteral("Thunderbird"), 2000), entry(3, QStringLiteral("GIMP"), 3000)});

    model.setFilter(QStringLiteral("fire"));
    QCOMPARE(model.rowCount(), 1);

    model.setFilter(QString());
    QCOMPARE(model.rowCount(), 3);
}

void TestClipboardModel::setFilterExcludesNonMatches() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("Firefox"), 1000), entry(2, QStringLiteral("Thunderbird"), 2000)});

    model.setFilter(QStringLiteral("zzzznomatch"));
    QCOMPARE(model.rowCount(), 0);
    QCOMPARE(model.idAtRow(0), -1);
}

void TestClipboardModel::bumpToTopMovesToFront() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000), entry(3, QStringLiteral("c"), 1000)});

    model.bumpToTop(3);
    QCOMPARE(model.idAtRow(0), 3);
    QCOMPARE(model.rowCount(), 3);
}

void TestClipboardModel::bumpToTopUnknownIdIsNoop() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 3000), entry(2, QStringLiteral("b"), 2000)});

    model.bumpToTop(9999);
    QCOMPARE(visibleIds(model), (QList<qint64>{1, 2}));
}

void TestClipboardModel::idAtRowAndTypeAtRowRejectOutOfRange() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 1000)});

    QCOMPARE(model.idAtRow(-1), -1);
    QCOMPARE(model.idAtRow(999), -1);
    QVERIFY(model.typeAtRow(-1).isEmpty());
    QVERIFY(model.typeAtRow(999).isEmpty());
    QCOMPARE(model.typeAtRow(0), QStringLiteral("text"));
}

void TestClipboardModel::entriesExposesEveryField() {
    vast::ClipboardModel model;
    model.reset({entry(1, QStringLiteral("a"), 1000), entry(2, QStringLiteral("b"), 2000)});

    const QVariantList all = model.entries();
    QCOMPARE(all.size(), 2);

    const QVariantMap first = all.first().toMap();
    for (const QString& key : {QStringLiteral("entryId"), QStringLiteral("type"), QStringLiteral("preview"), QStringLiteral("timestamp"), QStringLiteral("pinned"),
                               QStringLiteral("sourceApp"), QStringLiteral("mimeType"), QStringLiteral("sizeBytes"), QStringLiteral("fileName")})
        QVERIFY2(first.contains(key), qPrintable(QStringLiteral("missing %1").arg(key)));
    QCOMPARE(first.size(), 9);
}

void TestClipboardModel::countChangedFiresOnMutation() {
    vast::ClipboardModel model;
    QSignalSpy           spy(&model, &vast::ClipboardModel::countChanged);

    model.reset({entry(1, QStringLiteral("a"), 1000)});
    QVERIFY(spy.count() >= 1);

    const int afterReset = spy.count();
    model.prepend(entry(2, QStringLiteral("b"), 2000));
    QVERIFY(spy.count() > afterReset);

    const int afterPrepend = spy.count();
    model.removeById(1);
    QVERIFY(spy.count() > afterPrepend);
}

QTEST_MAIN(TestClipboardModel)
#include "tst_clipboardmodel.moc"
