#include "ColorPreview.hpp"

#include <qcolor.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qmap.h>
#include <qobject.h>
#include <qstring.h>
#include "../MaterialColor/PaletteBuilder.hpp"

namespace {

    QString paletteJson(const SMaterialPaletteResult& result) {
        QJsonObject colors;
        for (auto it = result.colors.constBegin(); it != result.colors.constEnd(); ++it)
            colors.insert(it.key(), it.value());
        if (!result.error.isEmpty()) {
            QJsonObject out;
            out.insert(QStringLiteral("error"), result.error);
            return QString::fromUtf8(QJsonDocument(out).toJson(QJsonDocument::Compact));
        }
        QJsonObject out;
        out.insert(QStringLiteral("colors"), colors);
        return QString::fromUtf8(QJsonDocument(out).toJson(QJsonDocument::Compact));
    }

} // namespace

ColorPreview::ColorPreview(QObject* parent) : QObject(parent) {}

QString ColorPreview::generate(const QString& imagePath, const QString& mode, const QString& scheme) {
    return paletteJson(buildPalette(imagePath, mode, scheme, false));
}

QString ColorPreview::generateFromColor(const QString& colorHex, const QString& mode, const QString& scheme) {
    return paletteJson(buildPaletteFromColor(colorHex, mode, scheme, false));
}
