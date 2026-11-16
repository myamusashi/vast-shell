#include "ClipboardContentClassifier.hpp"
#include "ClipboardEntry.hpp"
#include "WaylandDataControl.hpp"
#include "../FuzzyCore.hpp"

#include <qbytearray.h>
#include <qbytearrayview.h>
#include <qchar.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qhash.h>
#include <qregularexpression.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qstringview.h>
#include <qtypes.h>
#include <qurl.h>

#include <algorithm>
#include <array>
#include <iterator>
#include <utility>

namespace vast {

    namespace {
        constexpr qsizetype K_HTML_SEARCH_SLICE_MAX    = 32768;
        constexpr qsizetype K_MAX_SEARCH_CHARS         = 16384;
        constexpr qsizetype K_FUZZY_SCAN_LIMIT         = 4096;
        constexpr int       K_MAX_SUBSTRING_SCANS      = 16;
        constexpr double    K_FUZZY_MIN_RAW_PER_CHAR   = 0.55;
        constexpr double    K_FUZZY_TIER5_SCALE        = 0.45;
        constexpr double    K_TIER1_EXACT_FIELD        = 3.0;
        constexpr double    K_TIER2_EXACT_TOKEN        = 2.4;
        constexpr double    K_TIER3_TOKEN_PREFIX       = 1.9;
        constexpr double    K_TIER4_SUBSTRING          = 1.4;
        constexpr double    K_TIER5_FUZZY_CAP_PER_CHAR = 1.1;

        [[nodiscard]] bool  isWordBoundaryPos(const QString& text, qsizetype pos) {
            if (pos <= 0 || pos >= text.size())
                return true;

            const QChar ch = text.at(pos);
            if (!ch.isLetterOrNumber())
                return true;

            const QChar prev = text.at(pos - 1);
            return !prev.isLetterOrNumber();
        }

        [[nodiscard]] bool isEndBoundaryPos(const QString& text, qsizetype endPos) {
            if (endPos <= 0 || endPos >= text.size())
                return true;
            return !text.at(endPos).isLetterOrNumber();
        }

        [[nodiscard]] QString appendDecodedUrlText(const QString& text, qsizetype maxChars) {
            QString capped = text.size() > maxChars ? text.left(maxChars) : text;
            if (!capped.contains(u'%'))
                return capped;

            static const QRegularExpression percentEncodedRx(QStringLiteral("%[0-9A-Fa-f]{2}"));
            if (!percentEncodedRx.match(capped).hasMatch())
                return capped;

            const QString decoded = QUrl::fromPercentEncoding(capped.toUtf8());
            if (decoded.isEmpty() || decoded == capped)
                return capped;

            QString combined;
            combined.reserve(std::min(maxChars, capped.size() + decoded.size() + 1));
            combined.append(capped);
            combined.append(u'\n');
            combined.append(decoded);
            if (combined.size() > maxChars)
                combined.truncate(maxChars);
            return combined;
        }

        [[nodiscard]] QByteArray boundedUtf8(QStringView line) {
            QStringView slice = line.size() > fzy::K_MATCH_MAX_LEN ? line.left(fzy::K_MATCH_MAX_LEN) : line;
            QByteArray  utf8  = slice.toUtf8();
            while (utf8.size() > fzy::K_MATCH_MAX_LEN && !slice.isEmpty()) {
                const qsizetype excess = utf8.size() - fzy::K_MATCH_MAX_LEN;
                const qsizetype step   = std::max<qsizetype>(1, excess / 3);
                slice                  = slice.left(std::max<qsizetype>(0, slice.size() - step));
                utf8                   = slice.toUtf8();
            }
            return utf8;
        }

        [[nodiscard]] const QHash<QChar, QChar>& searchAccentLookup() {
            static const QHash<QChar, QChar> map = []() {
                static constexpr std::array entries = {
                    std::pair{'a', "aàáâãäåāăąǎǻạảấầẩẫậắằẳẵặ"},
                    std::pair{'c', "cçćĉċč"},
                    std::pair{'d', "dďđð"},
                    std::pair{'e', "eèéêëēĕėęěẹẻẽếềểễệ"},
                    std::pair{'g', "gĝğġģ"},
                    std::pair{'h', "hĥħ"},
                    std::pair{'i', "iìíîïĩīĭįıǐỉị"},
                    std::pair{'j', "jĵ"},
                    std::pair{'k', "kķ"},
                    std::pair{'l', "lĺļľŀł"},
                    std::pair{'n', "nñńņňŉŋ"},
                    std::pair{'o', "oòóôõöøōŏőơǒǫǭọỏốồổỗộớờởỡợ"},
                    std::pair{'r', "rŕŗř"},
                    std::pair{'s', "sśŝşšș"},
                    std::pair{'t', "tţťŧț"},
                    std::pair{'u', "uùúûüũūŭůűųưǔụủứừửữự"},
                    std::pair{'w', "wŵ"},
                    std::pair{'y', "yýÿŷỳỵỷỹ"},
                    std::pair{'z', "zźżž"},
                };
                QHash<QChar, QChar> h;
                for (const auto& [key, chars] : entries) {
                    const QString str = QString::fromUtf8(chars);
                    const QChar   canon(key);
                    for (QChar const c : str)
                        h.insert(c, canon);
                }
                h.insert(QChar(0x00A0), QChar(' '));
                return h;
            }();
            return map;
        }
    }

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

    [[nodiscard]] QString ClipboardContentClassifier::buildSearchText(ClipboardType type, const QString& content) {
        if (type == ClipboardType::Image || content.isEmpty())
            return {};

        if (type == ClipboardType::Html) {
            const QString    htmlSlice = extractHtmlSlice(content, K_HTML_SEARCH_SLICE_MAX);
            const QByteArray plain     = WaylandDataControl::htmlToPlainText(htmlSlice.toUtf8());
            return appendDecodedUrlText(QString::fromUtf8(plain), K_MAX_SEARCH_CHARS);
        }

        if (type == ClipboardType::Files) {
            const QStringList lines = content.split(u'\n', Qt::SkipEmptyParts);
            QStringList       decodedLines;
            decodedLines.reserve(lines.size());
            for (const QString& rawLine : lines) {
                const QString trimmed = rawLine.trimmed();
                if (trimmed.isEmpty() || trimmed.startsWith(u'#'))
                    continue;
                const QUrl url = QUrl::fromEncoded(trimmed.toUtf8());
                if (url.isValid() && url.isLocalFile())
                    decodedLines.append(url.toLocalFile());
                else
                    decodedLines.append(QUrl::fromPercentEncoding(trimmed.toUtf8()));
            }
            const QString joined = decodedLines.join(u'\n');
            return joined.size() > K_MAX_SEARCH_CHARS ? joined.left(K_MAX_SEARCH_CHARS) : joined;
        }

        return appendDecodedUrlText(content, K_MAX_SEARCH_CHARS);
    }

    [[nodiscard]] QChar ClipboardContentClassifier::normalizeSearchChar(QChar c) {
        const QChar lower = c.toLower();
        return searchAccentLookup().value(lower, lower);
    }

    [[nodiscard]] QString ClipboardContentClassifier::normalizeSearchText(const QString& text) {
        QString out;
        out.reserve(text.size());
        std::ranges::transform(text, std::back_inserter(out), &ClipboardContentClassifier::normalizeSearchChar);
        return out;
    }

    [[nodiscard]] double ClipboardContentClassifier::scoreSearchWord(const QString& normWord, const QByteArray& normWordUtf8, const QString& normField) {
        if (normWord.isEmpty() || normField.isEmpty())
            return 0.0;

        const auto wordLen = static_cast<double>(normWord.length());

        if (normField == normWord)
            return K_TIER1_EXACT_FIELD * wordLen;

        double    best  = 0.0;
        qsizetype from  = 0;
        int       scans = 0;
        while (scans < K_MAX_SUBSTRING_SCANS) {
            const qsizetype pos = normField.indexOf(normWord, from);
            if (pos < 0)
                break;

            ++scans;
            const bool startBoundary = isWordBoundaryPos(normField, pos);
            const bool endBoundary   = isEndBoundaryPos(normField, pos + normWord.length());
            double     posBonus      = (0.3 * wordLen) / (1.0 + static_cast<double>(pos) / 64.0);
            if (pos == 0)
                posBonus += 0.15 * wordLen;

            if (startBoundary && endBoundary)
                return K_TIER2_EXACT_TOKEN * wordLen + posBonus;

            const double tierBase = startBoundary ? K_TIER3_TOKEN_PREFIX : K_TIER4_SUBSTRING;
            best                  = std::max(best, tierBase * wordLen + posBonus);
            from                  = pos + 1;
        }

        if (best > 0.0)
            return best;

        if (normWord.length() < 2)
            return 0.0;

        const QStringView scanView{normField.constData(), std::min(normField.size(), K_FUZZY_SCAN_LIMIT)};
        qsizetype         lineStart = 0;
        while (lineStart < scanView.size()) {
            const qsizetype   lineEnd = scanView.indexOf(u'\n', lineStart);
            const qsizetype   len     = (lineEnd < 0 ? scanView.size() : lineEnd) - lineStart;
            const QStringView line    = scanView.sliced(lineStart, len).trimmed();
            lineStart                 = (lineEnd < 0) ? scanView.size() : (lineEnd + 1);

            if (line.length() < normWord.length())
                continue;

            const QByteArray        segmentUtf8 = boundedUtf8(line);
            const fzy::ScoreOutcome outcome     = fzy::scoredMatchUtf8(normWordUtf8, normWord.length(), segmentUtf8);
            if (outcome.matched && outcome.score >= K_FUZZY_MIN_RAW_PER_CHAR * wordLen) {
                const double scaled = std::min(K_TIER5_FUZZY_CAP_PER_CHAR * wordLen, outcome.score * K_FUZZY_TIER5_SCALE);
                best                = std::max(best, scaled);
            }
        }

        return best;
    }
}
