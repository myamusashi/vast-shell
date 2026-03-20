#include "ImageCache.hpp"

#include <QImageReader>
#include <QMutexLocker>
#include <QRunnable>
#include <QThreadPool>
#include <QDir>
#include <QFile>
#include <QQuickImageProvider>

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

void ImageCache::preload(const QString& path, QSize targetSize) {
    {
        QMutexLocker lock(&m_mutex);
        if (m_done.contains(path) || m_loading.contains(path))
            return;
        m_loading.insert(path);
    }
    QThreadPool::globalInstance()->start(new DecodeTask(this, path, targetSize));
}

QString ImageCache::saveProviderImage(const QString& qsUrl, const QString& cacheKey) {
    {
        QMutexLocker lock(&m_mutex);
        if (m_keyToPath.contains(cacheKey))
            return m_keyToPath.value(cacheKey);
    }

    if (!m_engine || !qsUrl.startsWith(u"image://"_s))
        return {};

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
    if (!provider || provider->imageType() != QQmlImageProviderBase::Image)
        return {};

    QSize        size;
    const QImage img = provider->requestImage(imageId, &size, {});
    if (img.isNull()) {
        qWarning() << "[ImageCache] Provider returned null image for" << qsUrl;
        return {};
    }

    const QString dir  = u"/tmp/vast-shell/notif-images"_s;
    const QString path = u"%1/%2.png"_s.arg(dir, cacheKey);
    QDir{}.mkpath(dir);

    if (!img.save(path)) {
        qWarning() << "[ImageCache] Failed to save notification image to" << path;
        return {};
    }

    const QString fileUrl = u"file://"_s + path;
    {
        QMutexLocker lock(&m_mutex);
        m_keyToPath.insert(cacheKey, fileUrl);
    }
    return fileUrl;
}

void ImageCache::evict(const QString& path) {
    QMutexLocker lock(&m_mutex);
    m_done.remove(path);
    m_loading.remove(path);
}

void ImageCache::store(const QString& path) {
    QMutexLocker lock(&m_mutex);
    m_loading.remove(path);
    m_done.insert(path);
}

QString ImageCache::cachedPath(const QString& cacheKey) const {
    QMutexLocker lock(&m_mutex);
    return m_keyToPath.value(cacheKey);
}

void ImageCache::evictKey(const QString& cacheKey) {
    QMutexLocker  lock(&m_mutex);
    const QString path = m_keyToPath.take(cacheKey);
    if (!path.isEmpty())
        QFile::remove(path.mid(7));
}
