#include <qdir.h>
#include <qfile.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qlist.h>
#include <qstring.h>
#include <qtest.h>
#include <qtemporarydir.h>

#include <memory>

#include "../../ImageCache/ImageCacheIndex.hpp"

namespace {

    // Writes a hand-crafted .index.json; save() only emits well-formed content.
    void writeIndex(const QString& dir, const QByteArray& rawJson) {
        QDir{}.mkpath(dir);
        QFile file(dir + QStringLiteral("/.index.json"));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(rawJson);
        file.close();
    }

} // namespace

class TestImageCacheIndex : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void toFileUrlAndFromFileUrlRoundTrip();
    void fromFileUrlPassesThroughUnprefixedInput();
    void toFileUrlAlwaysPrependsAndFromFileUrlStrips();
    void insertThenLookupReturnsTheUrl();
    void lookupOnAnUnknownKeyReturnsEmpty();
    void insertingTheSameKeyTwiceOverwrites();
    void removeReturnsThePreviousUrlAndDropsTheKey();
    void removeOnAnUnknownKeyReturnsEmpty();
    void allPathsReturnsEveryValue();
    void indexPersistsAcrossInstances();
    void loadDropsEntriesWhoseFileIsMissing();
    void loadIgnoresAJsonDocumentThatIsNotAnObject();
    void loadOnAMissingIndexFileYieldsAnEmptyIndex();
    void loadOnTruncatedJsonYieldsAnEmptyIndex();
    void indexFileLandsInsideTheInjectedDirectory();
    void staticDirectoryIsUnaffectedByInjection();

  private:
    // A fresh subdirectory per case. Never touches the real notif-images.
    [[nodiscard]] QString freshDir(const char* name) {
        const QString dir = mDir->path() + QLatin1Char('/') + QLatin1String(name);
        QDir{}.mkpath(dir);
        return dir;
    }

    std::unique_ptr<QTemporaryDir> mDir;
};

void TestImageCacheIndex::initTestCase() {
    mDir = std::make_unique<QTemporaryDir>();
    QVERIFY(mDir->isValid());
}

void TestImageCacheIndex::toFileUrlAndFromFileUrlRoundTrip() {
    for (const char* path : {"/tmp/vast-shell/notif-images/a.png", "/tmp/has space/b.png"}) {
        const QString p = QString::fromLatin1(path);
        QCOMPARE(ImageCacheIndex::fromFileUrl(ImageCacheIndex::toFileUrl(p)), p);
    }
}

void TestImageCacheIndex::fromFileUrlPassesThroughUnprefixedInput() {
    QCOMPARE(ImageCacheIndex::fromFileUrl(QStringLiteral("/tmp/x.png")), QStringLiteral("/tmp/x.png"));
    QCOMPARE(ImageCacheIndex::fromFileUrl(QString()), QString());
}

void TestImageCacheIndex::toFileUrlAlwaysPrependsAndFromFileUrlStrips() {
    const QString plain = QStringLiteral("/tmp/a.png");

    // fromFileUrl is idempotent; toFileUrl always prepends, so a prefixed value double-prefixes.
    // Callers pass plain paths.
    QCOMPARE(ImageCacheIndex::fromFileUrl(ImageCacheIndex::toFileUrl(plain)), plain);
    QCOMPARE(ImageCacheIndex::fromFileUrl(ImageCacheIndex::fromFileUrl(ImageCacheIndex::toFileUrl(plain))), plain);
    QCOMPARE(ImageCacheIndex::toFileUrl(ImageCacheIndex::toFileUrl(plain)), QStringLiteral("file://file:///tmp/a.png"));
}

void TestImageCacheIndex::insertThenLookupReturnsTheUrl() {
    ImageCacheIndex index(freshDir("insert"));
    const QString   url = ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/a.png"));

    index.insert(QStringLiteral("key"), url);

    QCOMPARE(index.lookup(QStringLiteral("key")), url);
}

void TestImageCacheIndex::lookupOnAnUnknownKeyReturnsEmpty() {
    ImageCacheIndex index(freshDir("miss"));

    // cachedPath() hands this to QML, so an empty string, not a missing value.
    QVERIFY(index.lookup(QStringLiteral("nope")).isEmpty());
}

void TestImageCacheIndex::insertingTheSameKeyTwiceOverwrites() {
    ImageCacheIndex index(freshDir("overwrite"));
    const QString   first  = ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/first.png"));
    const QString   second = ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/second.png"));

    index.insert(QStringLiteral("key"), first);
    index.insert(QStringLiteral("key"), second);

    QCOMPARE(index.lookup(QStringLiteral("key")), second);
    QCOMPARE(index.allPaths().size(), 1);
}

void TestImageCacheIndex::removeReturnsThePreviousUrlAndDropsTheKey() {
    ImageCacheIndex index(freshDir("remove"));
    const QString   url = ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/a.png"));
    index.insert(QStringLiteral("key"), url);

    QCOMPARE(index.remove(QStringLiteral("key")), url);

    QVERIFY(index.lookup(QStringLiteral("key")).isEmpty());
    QVERIFY(index.allPaths().isEmpty());
}

void TestImageCacheIndex::removeOnAnUnknownKeyReturnsEmpty() {
    ImageCacheIndex index(freshDir("removemiss"));
    QVERIFY(index.remove(QStringLiteral("nope")).isEmpty());
}

void TestImageCacheIndex::allPathsReturnsEveryValue() {
    ImageCacheIndex index(freshDir("allpaths"));
    index.insert(QStringLiteral("a"), ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/a.png")));
    index.insert(QStringLiteral("b"), ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/b.png")));
    index.insert(QStringLiteral("c"), ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/c.png")));

    const QList<QString> paths = index.allPaths();
    QCOMPARE(paths.size(), 3);
    // Order is not part of the contract: it is a QHash's value list.
    QVERIFY(paths.contains(ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/a.png"))));
    QVERIFY(paths.contains(ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/b.png"))));
    QVERIFY(paths.contains(ImageCacheIndex::toFileUrl(QStringLiteral("/tmp/c.png"))));
}

void TestImageCacheIndex::indexPersistsAcrossInstances() {
    const QString dir = freshDir("persist");
    // load() drops entries whose file is gone, so the file must exist.
    const QString real = dir + QStringLiteral("/persisted.png");
    {
        QFile file(real);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
        file.close();
    }

    ImageCacheIndex first(dir);
    const QString   url = ImageCacheIndex::toFileUrl(real);
    first.insert(QStringLiteral("key"), url);

    // The on-disk contract save()/load() exist for.
    ImageCacheIndex second(dir);
    QCOMPARE(second.lookup(QStringLiteral("key")), url);
}

void TestImageCacheIndex::loadDropsEntriesWhoseFileIsMissing() {
    const QString dir  = freshDir("dangling");
    const QString live = dir + QStringLiteral("/live.png");
    {
        QFile file(live);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
        file.close();
    }

    QJsonObject object;
    object.insert(QStringLiteral("live"), live);
    object.insert(QStringLiteral("dead"), dir + QStringLiteral("/gone.png"));
    writeIndex(dir, QJsonDocument(object).toJson(QJsonDocument::Compact));

    ImageCacheIndex index(dir);

    // load() stores the JSON value verbatim, so a plain path stays plain; the
    // file:// conversion is the caller's job, not the index's.
    QCOMPARE(index.lookup(QStringLiteral("live")), live);
    // The QFile::exists filter drops dead entries.
    QVERIFY(index.lookup(QStringLiteral("dead")).isEmpty());
    QCOMPARE(index.allPaths().size(), 1);
}

void TestImageCacheIndex::loadIgnoresAJsonDocumentThatIsNotAnObject() {
    const QString dir = freshDir("notobject");
    writeIndex(dir, QJsonDocument(QJsonArray{1, 2, 3}).toJson(QJsonDocument::Compact));

    ImageCacheIndex index(dir);

    QVERIFY(index.allPaths().isEmpty());
}

void TestImageCacheIndex::loadOnAMissingIndexFileYieldsAnEmptyIndex() {
    ImageCacheIndex index(freshDir("absent"));

    QVERIFY(index.allPaths().isEmpty());
}

void TestImageCacheIndex::loadOnTruncatedJsonYieldsAnEmptyIndex() {
    const QString dir = freshDir("truncated");
    // A half-written file is a real state: the process can die mid-save().
    writeIndex(dir, QByteArrayLiteral("{\"a\":"));

    ImageCacheIndex index(dir);

    QVERIFY(index.allPaths().isEmpty());
}

void TestImageCacheIndex::indexFileLandsInsideTheInjectedDirectory() {
    const QString dir  = freshDir("pathcheck");
    const QString real = dir + QStringLiteral("/a.png");
    {
        QFile file(real);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("x");
        file.close();
    }

    ImageCacheIndex index(dir);
    index.insert(QStringLiteral("key"), ImageCacheIndex::toFileUrl(real));

    // path() is private, so the injected-directory seam is proven by its
    // effect: the index file lands inside the directory that was passed in.
    const QString injected = dir + QStringLiteral("/.index.json");
    QVERIFY2(QFile::exists(injected), qPrintable(injected));

    // And what was written really is the index, readable by a fresh instance.
    ImageCacheIndex reloaded(dir);
    QCOMPARE(reloaded.lookup(QStringLiteral("key")), ImageCacheIndex::toFileUrl(real));
}

void TestImageCacheIndex::staticDirectoryIsUnaffectedByInjection() {
    ImageCacheIndex index(freshDir("staticcheck"));

    // The seam is instance-scoped: production still resolves to the real
    // notification directory, and injecting a directory does not change it.
    QCOMPARE(ImageCacheIndex::directory(), QStringLiteral("/tmp/vast-shell/notif-images"));
    QVERIFY(index.lookup(QStringLiteral("absent")).isEmpty());
}

QTEST_GUILESS_MAIN(TestImageCacheIndex)
#include "tst_imagecacheindex.moc"
