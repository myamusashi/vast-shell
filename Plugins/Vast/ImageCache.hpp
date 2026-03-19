#pragma once

#include <QHash>
#include <QImage>
#include <QMutex>
#include <QObject>
#include <QSet>
#include <QSize>
#include <QtQml/qqml.h>

class ImageCache : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(ImageCache)

  public:
    static ImageCache*             create(QQmlEngine*, QJSEngine*);
    static ImageCache*             instance();

    Q_INVOKABLE void               preload(const QString& path, QSize targetSize = {});
    Q_INVOKABLE void               evict(const QString& path);
    [[nodiscard]] Q_INVOKABLE bool isCached(const QString& path) const;

    QImage                         get(const QString& path) const;

  signals:
    void imageReady(const QString& path);

  private:
    explicit ImageCache(QObject* parent = nullptr);
    static ImageCache*     s_instance;

    mutable QMutex         m_mutex;
    QHash<QString, QImage> m_cache;
    QSet<QString>          m_loading;

    void                   store(const QString& path, QImage image);
    friend class DecodeTask;
};
