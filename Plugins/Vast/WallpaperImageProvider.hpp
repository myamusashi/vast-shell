#pragma once
#include <QQuickAsyncImageProvider>

class WallpaperImageProvider : public QQuickAsyncImageProvider {
  public:
    QQuickImageResponse* requestImageResponse(const QString& id, const QSize& requestedSize) override;
};
