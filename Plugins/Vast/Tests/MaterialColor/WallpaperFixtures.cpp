#include "WallpaperFixtures.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qlist.h>
#include <qstring.h>
#include <qstringlist.h>

namespace vast::test {

    namespace {

        constexpr const char* K_DATA_DIR = VAST_TEST_FIXTURE_DIR;

        QString               dataDir() {
            return QDir(QString::fromLatin1(K_DATA_DIR)).absolutePath();
        }

        QString manifestPath() {
            return QDir(dataDir()).filePath(QStringLiteral("manifest.json"));
        }

        struct SManifest {
            QStringList   files;
            QList<double> hues;
        };

        SManifest readManifest() {
            SManifest manifest;
            QFile     file(manifestPath());
            if (!file.open(QIODevice::ReadOnly))
                return manifest;

            const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
            if (!document.isObject())
                return manifest;

            const QJsonArray images = document.object().value(QStringLiteral("images")).toArray();
            for (const QJsonValueConstRef& value : images) {
                const QJsonObject image = value.toObject();
                manifest.files.append(image.value(QStringLiteral("file")).toString());
                manifest.hues.append(image.value(QStringLiteral("hue")).toDouble());
            }
            return manifest;
        }

    } // namespace

    QStringList wallpaperFixtures() {
        const SManifest manifest = readManifest();
        const QDir      root(dataDir());
        QStringList     paths;
        paths.reserve(manifest.files.size());
        for (const QString& file : manifest.files)
            paths.append(root.filePath(file));
        return paths;
    }

    QList<double> wallpaperFixtureHues() {
        return readManifest().hues;
    }

    bool requireWallpaperFixtures(QString& error) {
        const SManifest manifest = readManifest();
        if (manifest.files.isEmpty()) {
            error = QStringLiteral("no fixtures in %1 — run Plugins/Vast/Tests/MaterialColor/fetch_wallpapers.py").arg(manifestPath());
            return false;
        }

        const QDir root(dataDir());
        for (const QString& file : manifest.files) {
            if (!QFileInfo::exists(root.filePath(file))) {
                error = QStringLiteral("fixture %1 missing — run Plugins/Vast/Tests/MaterialColor/fetch_wallpapers.py").arg(file);
                return false;
            }
        }
        return true;
    }

} // namespace vast::test
