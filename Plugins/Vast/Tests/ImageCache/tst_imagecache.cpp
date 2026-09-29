#include <qcoreapplication.h>
#include <qdir.h>
#include <qfile.h>
#include <qimage.h>
#include <qjsengine.h>
#include <qqmlengine.h>
#include <qquickimageprovider.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>
#include <qtemporarydir.h>

#include <memory>

#include "../../ImageCache/ImageCache.hpp"

namespace {

    // imageType() is non-virtual, so the type must come from the base constructor.
    class TestImageProvider : public QQuickImageProvider {
      public:
        explicit TestImageProvider(QQmlImageProviderBase::ImageType type) : QQuickImageProvider(type) {}

        QImage requestImage(const QString& /*id*/, QSize* size, const QSize& /*requestedSize*/) override {
            ++mCalls;
            if (size)
                *size = QSize(4, 4);
            return mImage;
        }

        void setImage(const QImage& image) {
            mImage = image;
        }

        [[nodiscard]] int calls() const {
            return mCalls;
        }

      private:
        QImage mImage;
        int    mCalls{0};
    };

    // QVERIFY cannot be used in a value-returning function.
    [[nodiscard]] QString writePng(const QTemporaryDir& dir, const QString& name, const QSize& size) {
        QImage image(size, QImage::Format_RGB32);
        image.fill(QColor(40, 90, 180));
        const QString path = dir.path() + QLatin1Char('/') + name;
        if (!image.save(path))
            return {};
        return path;
    }

    [[nodiscard]] QString cachePathFrom(const QString& fileUrl) {
        return ImageCacheIndex::fromFileUrl(fileUrl);
    }

} // namespace

class TestImageCache : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void cleanup();
    void cleanupTestCase();

    void copyAndPreloadRejectsAnUnreadablePath();
    void copyAndPreloadRejectsANonImageFile();
    void copyAndPreloadWritesAPngAndReturnsAFileUrl();
    void copyAndPreloadIsDeterministicForTheSameSource();
    void copyAndPreloadEmitsImageReadyAfterPreloading();
    void evictLetsAPreloadRunAgain();

    void saveProviderImageRejectsANonImageUrl();
    void saveProviderImageRejectsAnUnknownProvider();
    void saveProviderImageRejectsANonImageProvider();
    void saveProviderImageRejectsANullProviderImage();
    void saveProviderImageCachesAndCachedPathReturnsTheSameUrl();
    void saveProviderImageReturnsTheCachedValueOnASecondCall();
    void evictKeyRemovesTheFileAndTheIndexEntry();
    void evictKeyOnAnUnknownKeyIsANoOp();
    void saveProviderImageQmlWrapsTheErrorAsAnEmptyString();

  private:
    [[nodiscard]] ImageCache* cache() const {
        return mCache;
    }

    // A unique source per case, so mDone cannot suppress the signal.
    [[nodiscard]] QString uniqueSource(const char* tag, const QSize& size = QSize(8, 8)) {
        const QString path = writePng(*mSource, QStringLiteral("%1-%2.png").arg(QString::fromLatin1(tag), QString::number(mSeq++)), size);
        Q_ASSERT(!path.isEmpty());
        return path;
    }

    // Drain completions from earlier cases, or spy.at(0) is a leftover path. Waits for two quiet
    // windows.
    void settleCompletions();

    // A failed case can leave tst-key-* behind and make the next run pass for the wrong reason.
    void                           evictTestKeys();

    std::unique_ptr<QTemporaryDir> mSource;
    std::unique_ptr<QQmlEngine>    mEngine;
    TestImageProvider*             mProvider   = nullptr;
    TestImageProvider*             mPixmapProv = nullptr;
    QString                        mProviderImage;
    ImageCache*                    mCache = nullptr;
    QStringList                    mCreated;
    int                            mSeq{0};
};

void TestImageCache::initTestCase() {
    mSource = std::make_unique<QTemporaryDir>();
    QVERIFY(mSource->isValid());

    mProviderImage = writePng(*mSource, QStringLiteral("provider.png"), QSize(4, 4));
    QVERIFY(!mProviderImage.isEmpty());

    mEngine = std::make_unique<QQmlEngine>();

    mProvider = new TestImageProvider(QQmlImageProviderBase::Image);
    mEngine->addImageProvider(QStringLiteral("qstest"), mProvider);

    mPixmapProv = new TestImageProvider(QQmlImageProviderBase::Pixmap);
    mEngine->addImageProvider(QStringLiteral("qstestpixmap"), mPixmapProv);

    // One instance per process; create() takes the engine so saveProviderImage passes its NoEngine
    // guard.
    mCache = ImageCache::create(mEngine.get(), nullptr);
    QVERIFY(mCache != nullptr);
}

void TestImageCache::evictTestKeys() {
    QDir dir(ImageCacheIndex::directory());
    for (const QString& name : dir.entryList({QStringLiteral("tst-key-*")}, QDir::Files))
        QFile::remove(dir.filePath(name));

    for (const QString& key : {QStringLiteral("tst-key-1"), QStringLiteral("tst-key-http")})
        mCache->evictKey(key);
}

void TestImageCache::settleCompletions() {
    QSignalSpy spy(cache(), &ImageCache::imageReady);
    int        last   = -1;
    int        stable = 0;
    while (stable < 2) {
        QTest::qWait(200);
        if (spy.count() == last)
            ++stable;
        else {
            stable = 0;
            last   = spy.count();
        }
    }
}

void TestImageCache::cleanup() {
    evictTestKeys();
}

void TestImageCache::cleanupTestCase() {
    evictTestKeys();
    for (const QString& path : std::as_const(mCreated))
        QFile::remove(path);
}

void TestImageCache::copyAndPreloadRejectsAnUnreadablePath() {
    QVERIFY(cache()->copyAndPreload(mSource->path() + QStringLiteral("/nope.png")).isEmpty());
}

void TestImageCache::copyAndPreloadRejectsANonImageFile() {
    const QString path = mSource->path() + QStringLiteral("/notreallyimage.png");
    QFile         file(path);
    QVERIFY(file.open(QIODevice::WriteOnly));
    file.write("this is not a png");
    file.close();

    QVERIFY(cache()->copyAndPreload(path).isEmpty());
}

void TestImageCache::copyAndPreloadWritesAPngAndReturnsAFileUrl() {
    const QString source = uniqueSource("copy");
    const QString url    = cache()->copyAndPreload(source);

    mCreated.append(cachePathFrom(url));

    QVERIFY(url.startsWith(QStringLiteral("file://")));
    QVERIFY(url.endsWith(QStringLiteral(".png")));

    const QString cached = cachePathFrom(url);
    QVERIFY2(QFile::exists(cached), qPrintable(cached));

    const QImage decoded(cached);
    QVERIFY(!decoded.isNull());
    QCOMPARE(decoded.size(), QSize(8, 8));
}

void TestImageCache::copyAndPreloadIsDeterministicForTheSameSource() {
    const QString source = uniqueSource("determinism");
    const QString first  = cache()->copyAndPreload(source);
    const QString second = cache()->copyAndPreload(source);

    mCreated.append(cachePathFrom(first));

    QVERIFY(!first.isEmpty());
    QCOMPARE(first, second);
    QVERIFY(QFile::exists(cachePathFrom(first)));
}

void TestImageCache::copyAndPreloadEmitsImageReadyAfterPreloading() {
    settleCompletions();

    const QString source = uniqueSource("ready");
    QSignalSpy    spy(cache(), &ImageCache::imageReady);

    const QString url = cache()->copyAndPreload(source);
    mCreated.append(cachePathFrom(url));
    QVERIFY(!url.isEmpty());

    // Covers the JobExecutor -> QueuedConnection hop; a dropped completion hangs here.
    QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 10000);

    QCOMPARE(spy.at(0).at(0).toString(), cachePathFrom(url));
}

void TestImageCache::evictLetsAPreloadRunAgain() {
    settleCompletions();

    const QString source = uniqueSource("evict");
    const QString url    = cache()->copyAndPreload(source);
    const QString cached = cachePathFrom(url);
    mCreated.append(cached);
    QVERIFY(!url.isEmpty());

    QTRY_VERIFY_WITH_TIMEOUT(QFile::exists(cached), 10000);

    // The first preload is done and drained.
    settleCompletions();

    // Wallpaper.qml:301.
    cache()->evict(cached);

    QSignalSpy spy(cache(), &ImageCache::imageReady);
    cache()->preload(source);

    QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 10000);
    // imageReady echoes the path given to preload, which here is the source.
    QCOMPARE(spy.at(0).at(0).toString(), source);
}

void TestImageCache::saveProviderImageRejectsANonImageUrl() {
    const auto result = cache()->saveProviderImage(QStringLiteral("http://example.invalid/x.png"), QStringLiteral("tst-key-http"));

    QVERIFY(!result.has_value());
    QCOMPARE(result.error(), ImageCacheError::InvalidUrl);
}

void TestImageCache::saveProviderImageRejectsAnUnknownProvider() {
    const auto result = cache()->saveProviderImage(QStringLiteral("image://nosuchprovider/1"), QStringLiteral("tst-key-noprov"));

    QVERIFY(!result.has_value());
    QCOMPARE(result.error(), ImageCacheError::NoProvider);
}

void TestImageCache::saveProviderImageRejectsANonImageProvider() {
    const auto result = cache()->saveProviderImage(QStringLiteral("image://qstestpixmap/1"), QStringLiteral("tst-key-pixmap"));

    QVERIFY(!result.has_value());
    QCOMPARE(result.error(), ImageCacheError::ProviderTypeMismatch);
}

void TestImageCache::saveProviderImageRejectsANullProviderImage() {
    mProvider->setImage(QImage());

    const auto result = cache()->saveProviderImage(QStringLiteral("image://qstest/1"), QStringLiteral("tst-key-null"));

    QVERIFY(!result.has_value());
    QCOMPARE(result.error(), ImageCacheError::NullImage);
}

void TestImageCache::saveProviderImageCachesAndCachedPathReturnsTheSameUrl() {
    mProvider->setImage(QImage(mProviderImage));

    const auto result = cache()->saveProviderImage(QStringLiteral("image://qstest/1"), QStringLiteral("tst-key-1"));

    QVERIFY(result.has_value());
    const QString url = *result;
    QVERIFY(url.startsWith(QStringLiteral("file://")));
    QVERIFY(url.endsWith(QStringLiteral("/tst-key-1.png")));
    QVERIFY(QFile::exists(cachePathFrom(url)));
    // Notifs.qml:86 reads this back.
    QCOMPARE(cache()->cachedPath(QStringLiteral("tst-key-1")), url);
}

void TestImageCache::saveProviderImageReturnsTheCachedValueOnASecondCall() {
    mProvider->setImage(QImage(mProviderImage));
    const auto first = cache()->saveProviderImage(QStringLiteral("image://qstest/1"), QStringLiteral("tst-key-1"));
    QVERIFY(first.has_value());

    const int  callsBefore = mProvider->calls();
    const auto second      = cache()->saveProviderImage(QStringLiteral("image://qstest/1"), QStringLiteral("tst-key-1"));

    QVERIFY(second.has_value());
    QCOMPARE(*second, *first);
    // The mIndex.lookup short-circuit means the provider is not consulted again.
    QCOMPARE(mProvider->calls(), callsBefore);
}

void TestImageCache::evictKeyRemovesTheFileAndTheIndexEntry() {
    mProvider->setImage(QImage(mProviderImage));
    const auto saved = cache()->saveProviderImage(QStringLiteral("image://qstest/1"), QStringLiteral("tst-key-1"));
    QVERIFY(saved.has_value());
    const QString path = cachePathFrom(*saved);
    QVERIFY(QFile::exists(path));

    // Notifs.qml:360.
    cache()->evictKey(QStringLiteral("tst-key-1"));

    QVERIFY(cache()->cachedPath(QStringLiteral("tst-key-1")).isEmpty());
    QVERIFY2(!QFile::exists(path), qPrintable(path));
}

void TestImageCache::evictKeyOnAnUnknownKeyIsANoOp() {
    cache()->evictKey(QStringLiteral("tst-key-never-existed"));
    QVERIFY(cache()->cachedPath(QStringLiteral("tst-key-never-existed")).isEmpty());
}

void TestImageCache::saveProviderImageQmlWrapsTheErrorAsAnEmptyString() {
    // Notifs.qml:283: the error becomes an empty string, not the enum.
    QVERIFY(cache()->saveProviderImageQml(QStringLiteral("http://example.invalid/x.png"), QStringLiteral("tst-key-qml")).isEmpty());
}

QTEST_GUILESS_MAIN(TestImageCache)
#include "tst_imagecache.moc"
