#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>

class Read : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:
    [[nodiscard]] static Q_INVOKABLE QString readFile(const QString& path);
    [[nodiscard]] static Q_INVOKABLE bool    fileExists(const QString& path);
    [[nodiscard]] static Q_INVOKABLE bool    isReadableFile(const QString& path);
};
