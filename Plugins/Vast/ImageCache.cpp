#include "ImageCache.hpp"

#include <QImageReader>
#include <QMutexLocker>
#include <QRunnable>
#include <QThreadPool>
#include <QDir>
#include <QFile>
#include <QQuickImageProvider>
#include <expected>
#include <shared_mutex>

using namespace Qt::StringLiterals;

class DecodeTask : public QObject, public QRunnable {
    Q_OBJECT

  public:
    DecodeTask(ImageCache* cache, const QString& path, QSize targetSize) : m_cache(cache), m_path(path), m_targetSize(targetSize) {
        setAutoDelete(true);
    }

    void run() override {
        QImageReader reader(m_path);
        reader.setAutoTransform(true);
        if (m_targetSize.isValid())
            reader.setScaledSize(reader.size().scaled(m_targetSize, Qt::KeepAspectRatioByExpanding));

        if (reader.read().isNull())
            qWarning() << "[ImageCache] Failed to preload:" << m_path;

        m_cache->store(m_path);
        emit m_cache->imageReady(m_path);
    }

  private:
    ImageCache* m_cache;
    QString     m_path;
    QSize       m_targetSize;
};

#include "ImageCache.moc"

ImageCache* ImageCache::s_instance = nullptr;

ImageCache::ImageCache(QObject* parent) : QObject(parent) {
    s_instance = this;
}

ImageCache* ImageCache::create(QQmlEngine* engine, QJSEngine*) {
    if (!s_instance)
        new ImageCache();
    s_instance->m_engine = engine;
    return s_instance;
}

ImageCache* ImageCache::instance() {
    return s_instance;
}

QString ImageCache::copyAndPreload(const QString& path, QSize targetSize) {
    QImage img(path);
    if (img.isNull()) {
        qWarning() << "[ImageCache] copyAndPreload: could not read" << path;
        return {};
    }

    const QString stablePath = u"/tmp/vast-shell/art-cache/%1.png"_s.arg(QString::number(qHash(path), 16));
    QDir{}.mkpath(u"/tmp/vast-shell/art-cache"_s);

    if (!img.save(stablePath))
        return {};

    preload(stablePath, targetSize);
    return u"file://"_s + stablePath;
}

void ImageCache::preload(const QString& path, QSize targetSize) {
    {
        std::unique_lock lock(m_rwMutex);
        if (m_done.contains(path) || m_loading.contains(path))
            return;
        m_loading.insert(path);
    }
    QThreadPool::globalInstance()->start(new DecodeTask(this, path, targetSize));
}

std::expected<QString, ImageCacheError> ImageCache::saveProviderImage(const QString& qsUrl, const QString& cacheKey) {
    {
        std::shared_lock lock(m_rwMutex);
        if (m_keyToPath.contains(cacheKey))
            return m_keyToPath.value(cacheKey);
    }

    if (!m_engine)
        return std::unexpected(ImageCacheError::NoEngine);
    if (!qsUrl.startsWith(u"image://"_s))
        return std::unexpected(ImageCacheError::InvalidUrl);

    // Parse "image://qsimage/7/1"
    //   host  = "qsimage"
    //   id    = "7/1"
    const qsizetype hostStart  = 8;
    const qsizetype slashAfter = qsUrl.indexOf(u'/', hostStart);
    if (slashAfter < 0)
        return {};

    const QString providerName = qsUrl.mid(hostStart, slashAfter - hostStart);
    const QString imageId      = qsUrl.mid(slashAfter + 1);

    auto*         base     = m_engine->imageProvider(providerName);
    auto*         provider = dynamic_cast<QQuickImageProvider*>(base);
    if (!provider)
        return std::unexpected(ImageCacheError::NoProvider);
    if (provider->imageType() != QQmlImageProviderBase::Image)
        return std::unexpected(ImageCacheError::ProviderTypeMismatch);

    QSize        size;
    const QImage img = provider->requestImage(imageId, &size, {});
    if (img.isNull())
        return std::unexpected(ImageCacheError::NullImage);

    const QString dir  = u"/tmp/vast-shell/notif-images"_s;
    const QString path = u"%1/%2.png"_s.arg(dir, cacheKey);
    QDir{}.mkpath(dir);

    if (!img.save(path))
        return std::unexpected(ImageCacheError::SaveFailed);

    const QString fileUrl = u"file://"_s + path;
    {
        std::unique_lock lock(m_rwMutex);
        m_keyToPath.insert(cacheKey, fileUrl);
    }
    return fileUrl;
}

void ImageCache::evict(const QString& path) {
    std::unique_lock lock(m_rwMutex);
    m_done.remove(path);
    m_loading.remove(path);
}

void ImageCache::store(const QString& path) {
    std::unique_lock lock(m_rwMutex);
    m_loading.remove(path);
    m_done.insert(path);

    constexpr qsizetype kMaxCacheEntries = 200;
    if (m_done.size() > kMaxCacheEntries) {
        auto      it       = m_done.begin();
        const qsizetype toRemove = m_done.size() - kMaxCacheEntries;
        for (int i = 0; i < toRemove && it != m_done.end(); ++i)
            it = m_done.erase(it);
    }
}

QString ImageCache::cachedPath(const QString& cacheKey) const {
    std::shared_lock lock(m_rwMutex);
    return m_keyToPath.value(cacheKey);
}

void ImageCache::evictKey(const QString& cacheKey) {
    std::unique_lock lock(m_rwMutex);
    const QString    path = m_keyToPath.take(cacheKey);
    if (!path.isEmpty())
        QFile::remove(path.mid(7));
}
