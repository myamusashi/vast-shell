#include "Write.hpp"
#include <qfile.h>
#include <qdebug.h>
#include <qobject.h>
#include <qstringview.h>

bool Write::writeFile(const QString& path, const QString& contents) {
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "[Vast.Utils] Failed to open file for writing:" << path << file.errorString();
        return false;
    }

    const QByteArray data = contents.toUtf8();
    if (file.write(data) != data.size()) {
        qWarning() << "[Vast.Utils] Failed to write file:" << path << file.errorString();
        return false;
    }

    return true;
}
