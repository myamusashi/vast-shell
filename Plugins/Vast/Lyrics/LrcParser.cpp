#include "LrcParser.hpp"

#include <qcontainerfwd.h>
#include <qlist.h>
#include <qminmax.h>
#include <qnamespace.h>
#include <qregularexpression.h>
#include <qstring.h>
#include <qtypes.h>

#include <yaml-cpp/yaml.h>

#include <algorithm>
#include <cmath>
#include <optional>
#include <string>

namespace {
    struct EnhancedWord {
        QString               text;
        qint64                startMs{0};
        std::optional<qint64> endMs;
        qsizetype             charStart{0};
    };

    struct LyricsfileWord {
        QString               text;
        qint64                startMs{0};
        std::optional<qint64> endMs;
    };

    struct LyricsfileLine {
        QString               text;
        qint64                startMs{0};
        std::optional<qint64> endMs;
        QList<LyricsfileWord> words;
    };

    [[nodiscard]] bool isVowel(QChar character) {
        static const QString vowels = QStringLiteral("aeiouyáéíóúàèìòùâêîôûäëïöüãõåæøœ");
        return vowels.contains(character.toLower());
    }

    [[nodiscard]] int countSyllables(const QString& token) {
        int  syllableCount    = 0;
        bool previousWasVowel = false;
        for (const QChar character : token) {
            const bool currentIsVowel = isVowel(character);
            if (currentIsVowel && !previousWasVowel)
                ++syllableCount;
            previousWasVowel = currentIsVowel;
        }
        return std::max(syllableCount, 1);
    }

    [[nodiscard]] double pauseWeightAfter(const QString& token) {
        if (token.isEmpty())
            return 0.0;
        const QChar lastCharacter = token.back();
        if (lastCharacter == u',' || lastCharacter == u';' || lastCharacter == u':')
            return vast::LrcParser::FALLBACK_COMMA_PAUSE_WEIGHT;
        if (lastCharacter == u'.' || lastCharacter == u'!' || lastCharacter == u'?' || lastCharacter == u'…')
            return vast::LrcParser::FALLBACK_SENTENCE_PAUSE_WEIGHT;
        return 0.0;
    }

    [[nodiscard]] QVariantMap makeWordEntry(const QString& text, qint64 startMs, qint64 endMs, qsizetype charStart) {
        QVariantMap entry;
        entry.insert(QStringLiteral("time"), startMs);
        entry.insert(QStringLiteral("startTime"), startMs);
        entry.insert(QStringLiteral("endTime"), endMs);
        entry.insert(QStringLiteral("text"), text);
        entry.insert(QStringLiteral("duration"), endMs - startMs);
        entry.insert(QStringLiteral("charStart"), charStart);
        entry.insert(QStringLiteral("charLength"), text.length());
        return entry;
    }

    [[nodiscard]] std::optional<qint64> readMilliseconds(const YAML::Node& node, const char* key) {
        const YAML::Node value = node[key];
        if (!value.IsDefined() || !value.IsScalar())
            return std::nullopt;
        return value.as<qint64>();
    }

    [[nodiscard]] QString readText(const YAML::Node& node, const char* key) {
        const YAML::Node value = node[key];
        if (!value.IsDefined() || !value.IsScalar())
            return {};
        return QString::fromStdString(value.as<std::string>());
    }
} // namespace

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
        Result              result;
        const auto          totalMs = static_cast<qint64>(totalDurationSecs * 1000.0);
        QList<EnhancedWord> enhancedWords;

        for (int i = 0; i < raw.size(); ++i) {
            const qint64  lineStart = raw.at(i).timeMs;
            const QString content   = raw.at(i).content;
            const qint64  lineEnd   = (i + 1 < raw.size()) ? raw.at(i + 1).timeMs : qMax(lineStart + LAST_LINE_TAIL_MS, totalMs);
            if (content.isEmpty())
                continue;

            static const QRegularExpression stripTagRe(QStringLiteral(R"(<[^>]+>)"));
            const qsizetype                 caretIdx  = content.indexOf('^');
            const QString                   srcText   = (caretIdx >= 0) ? content.left(caretIdx).trimmed() : content;
            const QString                   transText = (caretIdx >= 0) ? content.mid(caretIdx + 1).trimmed() : QString();
            QString                         cleanText = srcText;
            cleanText.remove(stripTagRe);
            cleanText = cleanText.trimmed();

            QVariantMap lineEntry;
            lineEntry.insert(QStringLiteral("time"), lineStart);
            lineEntry.insert(QStringLiteral("text"), cleanText);
            lineEntry.insert(QStringLiteral("translation"), transText);

            QVariantList words;
            auto         wit = wordRe.globalMatch(srcText);
            if (wit.hasNext()) {
                result.wordSynced = true;
                enhancedWords.clear();
                qsizetype searchPos = 0;
                while (wit.hasNext()) {
                    auto          wm      = wit.next();
                    const qint64  tagTime = parseTimestamp(wm.captured(1), wm.captured(2), wm.captured(3));
                    const QString text    = wm.captured(4).trimmed();
                    if (text.isEmpty()) {
                        // Empty-text tags mark the explicit end time of the preceding word.
                        if (!enhancedWords.isEmpty() && !enhancedWords.last().endMs.has_value())
                            enhancedWords.last().endMs = tagTime;
                        continue;
                    }
                    const qsizetype found     = cleanText.indexOf(text, searchPos);
                    const qsizetype charStart = (found >= 0) ? found : searchPos;
                    searchPos                 = charStart + text.length();

                    enhancedWords.append({
                        .text      = text,
                        .startMs   = tagTime,
                        .endMs     = std::nullopt,
                        .charStart = charStart,
                    });
                }
                words.reserve(enhancedWords.size());
                for (qsizetype wordIndex = 0; wordIndex < enhancedWords.size(); ++wordIndex) {
                    const EnhancedWord& word      = enhancedWords.at(wordIndex);
                    const qint64        startTime = word.startMs;
                    qint64              rawEnd    = lineEnd;
                    qint64              maxEnd    = qMax(startTime, lineEnd);
                    if (wordIndex + 1 < enhancedWords.size()) {
                        const qint64 nextStart = enhancedWords.at(wordIndex + 1).startMs;
                        maxEnd                 = qMax(startTime, nextStart);
                        rawEnd                 = word.endMs.value_or(nextStart);
                    } else if (word.endMs.has_value()) {
                        rawEnd = *word.endMs;
                    } else {
                        rawEnd = qMin(lineEnd, startTime + MAX_LAST_WORD_DURATION_MS);
                    }
                    const qint64 endTime = std::clamp(rawEnd, startTime, maxEnd);
                    words.append(makeWordEntry(word.text, startTime, endTime, word.charStart));
                }
            } else {
                words = interpolateWords(cleanText, lineStart, lineEnd);
            }

            lineEntry.insert(QStringLiteral("words"), words);
            result.lines.append(lineEntry);

            QVariantMap wlEntry;
            wlEntry.insert(QStringLiteral("time"), lineStart);
            wlEntry.insert(QStringLiteral("endTime"), lineEnd);
            wlEntry.insert(QStringLiteral("words"), words);
            result.wordLines.append(wlEntry);
        }

        result.synced = true;
        return result;
    }

    LrcParser::Result LrcParser::parseLyricsfile(const QString& yamlText, double totalDurationSecs) {
        QList<LyricsfileLine> rawLines;
        try {
            const YAML::Node root = YAML::Load(yamlText.toStdString());
            if (!root.IsDefined() || !root.IsMap())
                return {};
            const YAML::Node linesNode = root["lines"];
            if (!linesNode.IsDefined() || !linesNode.IsSequence())
                return {};

            for (const YAML::Node& lineNode : linesNode) {
                if (!lineNode.IsDefined() || !lineNode.IsMap())
                    continue;
                LyricsfileLine rawLine;
                rawLine.text                            = readText(lineNode, "text").trimmed();
                const std::optional<qint64> lineStartMs = readMilliseconds(lineNode, "start_ms");
                if (!lineStartMs.has_value())
                    continue;
                rawLine.startMs = *lineStartMs;
                rawLine.endMs   = readMilliseconds(lineNode, "end_ms");

                const YAML::Node wordsNode = lineNode["words"];
                if (wordsNode.IsDefined() && wordsNode.IsSequence()) {
                    for (const YAML::Node& wordNode : wordsNode) {
                        if (!wordNode.IsDefined() || !wordNode.IsMap())
                            continue;
                        const std::optional<qint64> wordStartMs = readMilliseconds(wordNode, "start_ms");
                        if (!wordStartMs.has_value())
                            continue;
                        rawLine.words.append({.text = readText(wordNode, "text"), .startMs = *wordStartMs, .endMs = readMilliseconds(wordNode, "end_ms")});
                    }
                }
                rawLines.append(rawLine);
            }
        } catch (const YAML::Exception&) { return {}; }

        Result     result;
        const auto totalMs = static_cast<qint64>(totalDurationSecs * 1000.0);

        for (qsizetype lineIndex = 0; lineIndex < rawLines.size(); ++lineIndex) {
            const LyricsfileLine& rawLine = rawLines.at(lineIndex);
            if (rawLine.text.isEmpty())
                continue;

            const bool   hasExplicitLineEnd = rawLine.endMs.has_value();
            const qint64 nextLineStartMs    = (lineIndex + 1 < rawLines.size()) ? rawLines.at(lineIndex + 1).startMs : qMax(rawLine.startMs + LAST_LINE_TAIL_MS, totalMs);
            const qint64 lineEndMs          = qMax(rawLine.startMs, rawLine.endMs.value_or(nextLineStartMs));

            QVariantList words;
            if (rawLine.words.isEmpty()) {
                words = interpolateWords(rawLine.text, rawLine.startMs, lineEndMs);
            } else {
                result.wordSynced   = true;
                qsizetype searchPos = 0;
                for (qsizetype wordIndex = 0; wordIndex < rawLine.words.size(); ++wordIndex) {
                    const LyricsfileWord& rawWord = rawLine.words.at(wordIndex);
                    const QString         text    = rawWord.text.trimmed();
                    if (text.isEmpty())
                        continue;

                    const qsizetype found     = rawLine.text.indexOf(text, searchPos);
                    const qsizetype charStart = (found >= 0) ? found : searchPos;
                    searchPos                 = charStart + text.length();

                    const bool   isLastWord  = (wordIndex + 1 == rawLine.words.size());
                    const qint64 nextStartMs = isLastWord ? lineEndMs : rawLine.words.at(wordIndex + 1).startMs;
                    const qint64 maxEndMs    = qMax(rawWord.startMs, nextStartMs);
                    qint64       rawEndMs    = nextStartMs;
                    if (rawWord.endMs.has_value())
                        rawEndMs = *rawWord.endMs;
                    else if (isLastWord && !hasExplicitLineEnd)
                        rawEndMs = rawWord.startMs + MAX_LAST_WORD_DURATION_MS;
                    const qint64 endMs = std::clamp(rawEndMs, rawWord.startMs, maxEndMs);

                    words.append(makeWordEntry(text, rawWord.startMs, endMs, charStart));
                }
            }

            QVariantMap lineEntry;
            lineEntry.insert(QStringLiteral("time"), rawLine.startMs);
            lineEntry.insert(QStringLiteral("text"), rawLine.text);
            lineEntry.insert(QStringLiteral("translation"), QString());
            lineEntry.insert(QStringLiteral("words"), words);
            result.lines.append(lineEntry);

            QVariantMap wordLineEntry;
            wordLineEntry.insert(QStringLiteral("time"), rawLine.startMs);
            wordLineEntry.insert(QStringLiteral("endTime"), lineEndMs);
            wordLineEntry.insert(QStringLiteral("words"), words);
            result.wordLines.append(wordLineEntry);
        }

        result.synced = !result.lines.isEmpty();
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
            lineEntry.insert(QStringLiteral("time"), -1);
            lineEntry.insert(QStringLiteral("text"), srcText);
            lineEntry.insert(QStringLiteral("translation"), transText);

            words.clear();
            const QList<QString> srcTextList = srcText.split(' ', Qt::SkipEmptyParts);
            words.reserve(srcTextList.size());
            qsizetype searchPos = 0;
            for (const QString& word : srcTextList) {
                const qsizetype found     = srcText.indexOf(word, searchPos);
                const qsizetype charStart = (found >= 0) ? found : searchPos;
                searchPos                 = charStart + word.length();
                words.append(makeWordEntry(word, -1, -1, charStart));
            }
            lineEntry.insert(QStringLiteral("words"), words);
            result.lines.append(lineEntry);

            QVariantMap wlEntry;
            wlEntry.insert(QStringLiteral("time"), -1);
            wlEntry.insert(QStringLiteral("endTime"), -1);
            wlEntry.insert(QStringLiteral("words"), words);
            result.wordLines.append(wlEntry);
        }

        return result;
    }

    QVariantList LrcParser::interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs) {
        const QStringList tokens = text.split(' ', Qt::SkipEmptyParts);
        if (tokens.isEmpty())
            return {};

        QList<double> spokenWeights;
        QList<double> pauseWeights;
        spokenWeights.reserve(tokens.size());
        pauseWeights.reserve(tokens.size());
        double totalWeight    = 0.0;
        qint64 totalSyllables = 0;
        for (qsizetype index = 0; index < tokens.size(); ++index) {
            const int    syllables   = countSyllables(tokens.at(index));
            const bool   isLastToken = (index + 1 == tokens.size());
            const double pauseWeight = isLastToken ? 0.0 : pauseWeightAfter(tokens.at(index));
            spokenWeights.append(syllables);
            pauseWeights.append(pauseWeight);
            totalWeight += syllables + pauseWeight;
            totalSyllables += syllables;
        }

        const qint64 availableMs           = qMax<qint64>(0, lineEndMs - lineStartMs);
        const qint64 maxBudgetMs           = qMax<qint64>(tokens.size() * FALLBACK_MAX_MS_PER_WORD, totalSyllables * FALLBACK_MAX_MS_PER_SYLLABLE);
        const qint64 budgetMs              = std::min(static_cast<qint64>(static_cast<double>(availableMs) * FALLBACK_LINE_FILL_RATIO), maxBudgetMs);
        const double millisecondsPerWeight = static_cast<double>(budgetMs) / totalWeight;

        QVariantList words;
        words.reserve(tokens.size());
        double    cursorWeight = 0.0;
        qsizetype searchPos    = 0;
        for (qsizetype index = 0; index < tokens.size(); ++index) {
            const QString&  token     = tokens.at(index);
            const qint64    startMs   = lineStartMs + std::llround(cursorWeight * millisecondsPerWeight);
            const qint64    endMs     = lineStartMs + std::llround((cursorWeight + spokenWeights.at(index)) * millisecondsPerWeight);
            const qsizetype found     = text.indexOf(token, searchPos);
            const qsizetype charStart = (found >= 0) ? found : searchPos;
            searchPos                 = charStart + token.length();

            words.append(makeWordEntry(token, startMs, endMs, charStart));
            cursorWeight += spokenWeights.at(index) + pauseWeights.at(index);
        }
        return words;
    }
}
