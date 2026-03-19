#include "ImageCache.hpp"

#include <QImageReader>
#include <QMutexLocker>
#include <QRunnable>
#include <QThreadPool>

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

ImageCache* ImageCache::create(QQmlEngine*, QJSEngine*) {
    if (!s_instance)
        new ImageCache();
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
