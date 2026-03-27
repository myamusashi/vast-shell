#pragma once

#include <QByteArray>
#include <QString>

namespace Vast {

    enum class ClipboardType {
        Text,
        Html,
        Image,
        Files,
    };

    struct ClipboardEntry {
        qint64             id   = -1;
        ClipboardType      type = ClipboardType::Text;
        QString            content;
        QByteArray         data;
        QString            mimeType{};
        QByteArray         hash{};
        bool               pinned = false;
        QString            sourceApp{};
        qint64             sizeBytes = 0;
        qint64             timestamp = 0;

        [[nodiscard]] bool isImage() const noexcept {
            return type == ClipboardType::Image;
        }

        [[nodiscard]] QString typeString() const noexcept {
            switch (type) {
                case ClipboardType::Text: return QStringLiteral("text");
                case ClipboardType::Html: return QStringLiteral("html");
                case ClipboardType::Image: return QStringLiteral("image");
                case ClipboardType::Files: return QStringLiteral("files");
            }
            return QStringLiteral("text");
        }

        [[nodiscard]] static ClipboardType typeFromString(const QString& s) noexcept {
            if (s == u"html")
                return ClipboardType::Html;
            if (s == u"image")
                return ClipboardType::Image;
            if (s == u"files")
                return ClipboardType::Files;
            return ClipboardType::Text;
        }
    };

}
