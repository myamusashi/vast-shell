#include "WallpaperImageProvider.hpp"
#include "ImageCache.hpp"

#include <QQuickImageResponse>

class WallpaperResponse : public QQuickImageResponse {
  public:
    WallpaperResponse(const QString& path, QSize requestedSize) {
        auto* cache = ImageCache::instance();

        if (cache->isCached(path)) {
            m_image = cache->get(path);
            emit finished();
            return;
        }

        QObject::connect(
            cache, &ImageCache::imageReady, this,
            [this, cache, path](const QString& ready) {
                if (ready != path)
                    return;
                m_image = cache->get(path);
                emit finished();
            },
            Qt::QueuedConnection);

        cache->preload(path, requestedSize);
    }

    QQuickTextureFactory* textureFactory() const override {
        return QQuickTextureFactory::textureFactoryForImage(m_image);
    }

  private:
    QImage m_image;
};

QQuickImageResponse* WallpaperImageProvider::requestImageResponse(const QString& id, const QSize& requestedSize) {
    const QString path = "/" + id;
    return new WallpaperResponse(path, requestedSize);
}
