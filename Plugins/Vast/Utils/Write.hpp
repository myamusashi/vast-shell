#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

class Write : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:
    [[nodiscard]] static Q_INVOKABLE bool writeFile(const QString& path, const QString& contents);
};
