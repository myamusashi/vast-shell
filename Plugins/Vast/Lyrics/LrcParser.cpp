#include "LrcParser.hpp"

#include <qcontainerfwd.h>
#include <qlist.h>
#include <qminmax.h>
#include <qnamespace.h>
#include <qregularexpression.h>
#include <qstring.h>
#include <qtypes.h>

#include <algorithm>

namespace vast {

    qint64 LrcParser::parseTimestamp(const QString& mm, const QString& ss, const QString& frac) {
        const int min = mm.toInt();
        const int sec = ss.toInt();
        const int ms  = (frac.length() == 2) ? frac.toInt() * 10 : frac.toInt();
        return static_cast<qint64>(min * 60 + sec) * 1000 + ms;
    }

    LrcParser::Result LrcParser::parseLrc(const QString& lrc, double totalDurationSecs) {
        static const QRegularExpression lineRe(QStringLiteral(R"(\[(\d{2}):(\d{2})\.(\d{2,3})\](.*))"));
        static const QRegularExpression wordRe(QStringLiteral(R"(<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*))"));

        struct RawLine {
            qint64  timeMs;
            QString content;
        };
        QList<RawLine>       raw;

        const QList<QString> trimmedLyricLine = lrc.split('\n');
        for (const QString& line : trimmedLyricLine) {
            auto m = lineRe.match(line.trimmed());
            if (!m.hasMatch())
                continue;
            raw.append({.timeMs = parseTimestamp(m.captured(1), m.captured(2), m.captured(3)), .content = m.captured(4).trimmed()});
        }
        if (raw.isEmpty())
            return {};
        Result     result;
        const auto totalMs = static_cast<qint64>(totalDurationSecs * 1000.0);

        for (int i = 0; i < raw.size(); ++i) {
            const qint64  lineStart = raw[i].timeMs;
            const QString content   = raw[i].content;
            const qint64  lineEnd   = (i + 1 < raw.size()) ? raw[i + 1].timeMs : qMax(lineStart + 5000, totalMs);
            if (content.isEmpty())
                continue;

            const qsizetype caretIdx  = content.indexOf('^');
            const QString   srcText   = (caretIdx >= 0) ? content.left(caretIdx).trimmed() : content;
            const QString   transText = (caretIdx >= 0) ? content.mid(caretIdx + 1).trimmed() : QString();

            QVariantMap     lineEntry;
            lineEntry[QStringLiteral("time")]        = lineStart;
            lineEntry[QStringLiteral("text")]        = srcText;
            lineEntry[QStringLiteral("translation")] = transText;
            result.lines.append(lineEntry);

            QVariantList words;
            auto         wit = wordRe.globalMatch(srcText);
            if (wit.hasNext()) {
                result.wordSynced = true;
                while (wit.hasNext()) {
                    auto          wm   = wit.next();
                    const QString text = wm.captured(4).trimmed();
                    if (text.isEmpty())
                        continue;
                    QVariantMap w;
                    w[QStringLiteral("time")] = parseTimestamp(wm.captured(1), wm.captured(2), wm.captured(3));
                    w[QStringLiteral("text")] = text;
                    words.append(w);
                }
                for (int j = 0; j < words.size(); ++j) {
                    QVariantMap  w     = words[j].toMap();
                    qint64 const t     = w[QStringLiteral("time")].toLongLong();
                    qint64       nextT = lineEnd;
                    if (j + 1 < words.size())
                        nextT = words[j + 1].toMap()[QStringLiteral("time")].toLongLong();
                    else {
                        qint64 const maxLastWord = 1500;
                        if (nextT - t > maxLastWord)
                            nextT = t + maxLastWord;
                    }
                    w[QStringLiteral("duration")] = qMax<qint64>(0, nextT - t);
                    words.replace(j, w);
                }
            } else {
                static const QRegularExpression rx(QStringLiteral(R"(<[^>]+>)"));
                QString                         plain = srcText;
                plain.remove(rx);
                words = interpolateWords(plain.trimmed(), lineStart, lineEnd);
            }

            QVariantMap wlEntry;
            wlEntry[QStringLiteral("time")]  = lineStart;
            wlEntry[QStringLiteral("words")] = words;
            result.wordLines.append(wlEntry);
        }

        result.synced = true;
        return result;
    }
    LrcParser::Result LrcParser::parsePlain(const QString& plain) {
        Result               result;

        const QList<QString> plainList = plain.split('\n');
        QList<QVariant>      words;
        for (const QString& raw : plainList) {
            const QString text = raw.trimmed();
            if (text.isEmpty())
                continue;

            const qsizetype caretIdx  = text.indexOf('^');
            const QString   srcText   = (caretIdx >= 0) ? text.left(caretIdx).trimmed() : text;
            const QString   transText = (caretIdx >= 0) ? text.mid(caretIdx + 1).trimmed() : QString();

            QVariantMap     lineEntry;
            lineEntry[QStringLiteral("time")]        = -1;
            lineEntry[QStringLiteral("text")]        = srcText;
            lineEntry[QStringLiteral("translation")] = transText;
            result.lines.append(lineEntry);

            words.clear();
            const QList<QString> srcTextList = srcText.split(' ', Qt::SkipEmptyParts);
            words.reserve(srcTextList.size());
            for (const QString& word : srcTextList) {
                QVariantMap w;
                w[QStringLiteral("time")]     = -1;
                w[QStringLiteral("text")]     = word;
                w[QStringLiteral("duration")] = 0;
                words.append(w);
            }
            QVariantMap wlEntry;
            wlEntry[QStringLiteral("time")]  = -1;
            wlEntry[QStringLiteral("words")] = words;
            result.wordLines.append(wlEntry);
        }

        return result;
    }

    QVariantList LrcParser::interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs) {
        const QStringList tokens = text.split(' ', Qt::SkipEmptyParts);
        if (tokens.isEmpty())
            return {};

        qint64 totalLen = 0;
        for (const QString& t : tokens) {
            totalLen += t.length();
        }

        qint64       durationGap = lineEndMs - lineStartMs;
        const qint64 maxDuration = tokens.size() * 800;
        durationGap              = std::min(durationGap, maxDuration);
        const auto   totalWeight = static_cast<double>(totalLen + tokens.size());

        QVariantList words;
        words.reserve(tokens.size());
        qint64 currentMs = lineStartMs;
        for (const QString& t : tokens) {
            const double fraction  = static_cast<double>(t.length() + 1) / totalWeight;
            const auto   wDuration = static_cast<qint64>(static_cast<double>(durationGap) * fraction);

            QVariantMap  w;
            w[QStringLiteral("time")]     = currentMs;
            w[QStringLiteral("text")]     = t;
            w[QStringLiteral("duration")] = wDuration;
            words.append(w);
            currentMs += wDuration;
        }
        return words;
    }
}
