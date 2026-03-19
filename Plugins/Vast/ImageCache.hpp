#pragma once

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
    static ImageCache* create(QQmlEngine*, QJSEngine*);
    static ImageCache* instance();

    Q_INVOKABLE void   preload(const QString& path, QSize targetSize = {});
    Q_INVOKABLE void   evict(const QString& path);

  signals:
    void imageReady(const QString& path);

  private:
    explicit ImageCache(QObject* parent = nullptr);
    static ImageCache* s_instance;

    mutable QMutex     m_mutex;
    QSet<QString>      m_loading;
    QSet<QString>      m_done;

    void               store(const QString& path);
    friend class DecodeTask;
};
