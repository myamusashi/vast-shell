#pragma once

#include <QMutex>
#include <QObject>
#include <QSet>
#include <QHash>
#include <QSize>
#include <QtQml/qqml.h>

class QQmlEngine;

class ImageCache : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(ImageCache)

  public:
    static ImageCache*                create(QQmlEngine*, QJSEngine*);
    static ImageCache*                instance();

    Q_INVOKABLE void                  preload(const QString& path, QSize targetSize = {});
    Q_INVOKABLE void                  evict(const QString& path);

    [[nodiscard]] Q_INVOKABLE QString saveProviderImage(const QString& qsUrl, const QString& cacheKey);
    [[nodiscard]] Q_INVOKABLE QString cachedPath(const QString& cacheKey) const;

    Q_INVOKABLE void                  evictKey(const QString& cacheKey);

  signals:
    void imageReady(const QString& path);

  private:
    explicit ImageCache(QObject* parent = nullptr);
    static ImageCache*      s_instance;

    QQmlEngine*             m_engine = nullptr;

    mutable QMutex          m_mutex;
    QSet<QString>           m_loading;
    QSet<QString>           m_done;
    QHash<QString, QString> m_keyToPath;

    void                    store(const QString& path);
    friend class DecodeTask;
};
