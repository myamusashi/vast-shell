#include "Read.hpp"
#include <qfile.h>
#include <qdebug.h>
#include <qlogging.h>
#include <qobject.h>

QString Read::readFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[Vast.Utils] Failed to open file for reading:" << path << file.errorString();
        return {};
    }

    return QString::fromUtf8(file.readAll());
}
