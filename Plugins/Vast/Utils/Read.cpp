#include "Read.hpp"
#include <qdebug.h>
#include <qfile.h>
#include <qfileinfo.h>
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

bool Read::fileExists(const QString& path) {
    return !path.isEmpty() && QFileInfo::exists(path);
}

bool Read::isReadableFile(const QString& path) {
    if (path.isEmpty())
        return false;

    const QFileInfo info(path);
    return info.exists() && info.isFile() && info.isReadable();
}
