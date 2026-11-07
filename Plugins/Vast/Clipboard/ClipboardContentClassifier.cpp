#include "ClipboardContentClassifier.hpp"
#include "ClipboardEntry.hpp"
#include "WaylandDataControl.hpp"

#include <qbytearray.h>
#include <qbytearrayview.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qchar.h>
#include <qstring.h>
#include <qregularexpression.h>

#include <algorithm>

namespace vast {

    [[nodiscard]] ClipboardType ClipboardContentClassifier::typeFromMime(const QString& mimeType) {
        if (mimeType == QStringLiteral("image/png"))
            return ClipboardType::Image;
        if (mimeType == QStringLiteral("text/html"))
            return ClipboardType::Html;
        if (mimeType == QStringLiteral("text/uri-list"))
            return ClipboardType::Files;
        return ClipboardType::Text;
    }

    [[nodiscard]] bool ClipboardContentClassifier::isBlankTextOrHtml(ClipboardType type, const QByteArray& content) {
        if (type != ClipboardType::Text && type != ClipboardType::Html)
            return false;
        if (content.isEmpty())
            return true;

        const auto check = QByteArrayView{content}.first(std::min<qsizetype>(content.size(), 4096));
        for (const char rawCh : check) {
            const auto ch = static_cast<unsigned char>(rawCh);
            if (ch > 0x20 && ch < 0x7F)
                return false;
        }

        const auto text = QString::fromUtf8(content);
        return text.isEmpty() || std::ranges::all_of(text, [](QChar c) { return c.isSpace(); });
    }

    [[nodiscard]] QString ClipboardContentClassifier::extractHtmlSlice(const QString& content, qsizetype maxChars) {
        if (content.size() <= maxChars)
            return content;

        qsizetype startIdx = content.indexOf(u"<!--StartFragment-->", 0, Qt::CaseInsensitive);
        if (startIdx != -1) {
            startIdx += 20;
        } else {
            startIdx = content.indexOf(u"<body", 0, Qt::CaseInsensitive);
            if (startIdx != -1) {
                startIdx = content.indexOf(u'>', startIdx);
                if (startIdx != -1)
                    ++startIdx;
                else
                    startIdx = 0;
            } else {
                const qsizetype   searchLimit = std::min<qsizetype>(content.size(), 65536);
                const QStringView prefix      = QStringView{content}.first(searchLimit);
                const qsizetype   headEnd     = prefix.lastIndexOf(u"</head>", -1, Qt::CaseInsensitive);
                if (headEnd != -1) {
                    startIdx = headEnd + 7;
                } else {
                    const qsizetype styleEnd = prefix.lastIndexOf(u"</style>", -1, Qt::CaseInsensitive);
                    if (styleEnd != -1)
                        startIdx = styleEnd + 8;
                    else
                        startIdx = 0;
                }
            }
        }

        return content.mid(startIdx, maxChars);
    }

    [[nodiscard]] QString ClipboardContentClassifier::buildPreview(ClipboardType type, const QString& content) {
        if (type != ClipboardType::Html)
            return content.size() > 1024 ? content.left(1024) : content;

        const QString                   htmlSlice = extractHtmlSlice(content, 8192);
        const QByteArray                plain     = WaylandDataControl::htmlToPlainText(htmlSlice.toUtf8());
        QString                         text      = QString::fromUtf8(plain);

        static const QRegularExpression whitespaceRun(QStringLiteral("[\\s\\x{00A0}]+"));
        text.replace(whitespaceRun, QStringLiteral(" "));
        return text.trimmed();
    }

    [[nodiscard]] ClipboardEntry ClipboardContentClassifier::buildEntry(const QString& mimeType, const QByteArray& content, const QString& fileName, const QString& sourceApp) {
        ClipboardEntry entry;
        entry.type      = typeFromMime(mimeType);
        entry.content   = entry.isImage() ? QString{} : QString::fromUtf8(content);
        entry.data      = entry.isImage() ? content : QByteArray{};
        entry.mimeType  = mimeType;
        entry.pinned    = false;
        entry.sourceApp = sourceApp;
        entry.sizeBytes = content.size();
        entry.timestamp = QDateTime::currentMSecsSinceEpoch();
        entry.fileName  = entry.isImage() ? fileName : QString{};

        entry.hash = QCryptographicHash::hash(content, QCryptographicHash::Sha256);
        return entry;
    }
}
