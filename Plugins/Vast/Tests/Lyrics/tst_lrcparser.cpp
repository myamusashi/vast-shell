#include <qlist.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include "../../Lyrics/LrcParser.hpp"

namespace {

    [[nodiscard]] QVariantMap lineAt(const vast::LrcParser::Result& r, int i) {
        return r.lines.at(i).toMap();
    }

    [[nodiscard]] QVariantList wordsAt(const vast::LrcParser::Result& r, int i) {
        return r.wordLines.at(i).toMap().value(QStringLiteral("words")).toList();
    }

    [[nodiscard]] qint64 wordTime(const QVariantList& words, int j) {
        return words.at(j).toMap().value(QStringLiteral("time")).toLongLong();
    }

    [[nodiscard]] qint64 wordDuration(const QVariantList& words, int j) {
        return words.at(j).toMap().value(QStringLiteral("duration")).toLongLong();
    }

    [[nodiscard]] QString wordText(const QVariantList& words, int j) {
        return words.at(j).toMap().value(QStringLiteral("text")).toString();
    }

    [[nodiscard]] qint64 totalWordDuration(const QVariantList& words) {
        qint64 sum = 0;
        for (const auto& w : words)
            sum += w.toMap().value(QStringLiteral("duration")).toLongLong();
        return sum;
    }

    const char* const TEN_TOKENS = "a bb ccc dddd eeeee f g h i j";

}

class TestLrcParser : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void parseLrcReturnsADefaultResultWhenNoLineMatches();
    void parsesTwoDigitCentisecondFraction();
    void parsesThreeDigitMillisecondFraction();
    void rejectsOneDigitFraction();
    void rejectsTimestampWithoutAFraction();
    void rejectsSingleDigitMinutes();
    void skipsLrcMetadataTags();
    void setsSyncedForAnyMatchedLine();

    void splitsTranslationOnTheFirstCaret();
    void translationIsEmptyWhenThereIsNoCaret();
    void onlyTheFirstCaretSplits();
    void translationIsTrimmed();

    void lastLineEndsAtFiveSecondsPastItsStartWhenTheTrackIsShorter();
    void lastLineEndsAtTheTotalDurationWhenTheTrackIsLonger();
    void aNonFinalLineEndsAtTheNextTimestamp();
    void anEmptyLineIsDroppedButStillBoundsThePreviousLine();

    void interpolatesWordDurationsBySyllableCount();
    void interpolatedWordTimesAreCumulative();
    void capsInterpolatedDurationAtFallbackBudget();
    void stripsStrayAngleTagsBeforeInterpolating();
    void wordSyncedIsFalseForInterpolatedLines();
    void anEmptyLineYieldsAnEmptyWordList();

    void parsesWordTagsIntoWords();
    void wordTagDurationSpansToTheNextTag();
    void capsTheLastWordAtMaxLastWordDurationMs();
    void wordTagsAcceptCentisecondAndMillisecondFractions();
    void duplicateWordTagTimesGiveZeroDuration();
    void dropsWordTagsWithEmptyText();
    void wordSyncedIsTrueWhenAnyLineCarriesTags();
    void stripsWordTagsFromDisplayLineText();
    void recordsCharSpansForWordSyncedAndInterpolatedLines();
    void capsSingleTokenCjkLineAtFallbackMaxMsPerWord();
    void explicitClosingTagSetsWordEndAndFinalWordBypassesCap();
    void clampsWordEndBetweenStartAndNextWordStart();
    void linesExposeWordsWithStartEndAndDerivedDuration();

    void parseLyricsfileWithHeldWords();
    void parseLyricsfileLastWordUsesLineEndMs();
    void parseLyricsfileMissingEndMs();
    void parseLyricsfileEmptyTextSeparatorLines();
    void parseLyricsfileWordsNotMatchingLineText();
    void parseLyricsfileInvalidYamlFallsBackToSyncedLyrics();
    void enhancedLrcHeldFinalWordCappedAtMaxLastWordDurationMs();
    void fallbackCommaCreatesPauseGapBeforeNextWord();

    void outOfOrderLineTimestampsClampWordDurationToZero();

    void parsePlainMarksEverythingUntimed();
    void parsePlainLeavesSyncedAndWordSyncedFalse();
    void parsePlainSkipsBlankLines();
    void parsePlainSplitsTranslationOnTheFirstCaret();
    void parsePlainSplitsWordsOnSpaces();
    void parsePlainTreatsLrcTagsAsLiteralText();
    void parsePlainOnEmptyInputYieldsEmptyLists();
    void linesAndWordLinesStayIndexAligned();
};

void TestLrcParser::parseLrcReturnsADefaultResultWhenNoLineMatches() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("hello world"), 100.0);

    QVERIFY(r.lines.isEmpty());
    QVERIFY(r.wordLines.isEmpty());
    QVERIFY(!r.synced);
    QVERIFY(!r.wordSynced);
}

void TestLrcParser::parsesTwoDigitCentisecondFraction() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.05]x"), 0.0);
    QCOMPARE(lineAt(r, 0).value(QStringLiteral("time")).toLongLong(), 10050ll);
}

void TestLrcParser::parsesThreeDigitMillisecondFraction() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.005]x"), 0.0);
    QCOMPARE(lineAt(r, 0).value(QStringLiteral("time")).toLongLong(), 10005ll);
}

void TestLrcParser::rejectsOneDigitFraction() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.5]x"), 0.0);
    QVERIFY(r.lines.isEmpty());
}

void TestLrcParser::rejectsTimestampWithoutAFraction() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10]x"), 0.0);
    QVERIFY(r.lines.isEmpty());
}

void TestLrcParser::rejectsSingleDigitMinutes() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[0:10.00]x"), 0.0);
    QVERIFY(r.lines.isEmpty());
}

void TestLrcParser::skipsLrcMetadataTags() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[ar:Artist]\n"
                                                            "[ti:Title]\n"
                                                            "[al:Album]\n"
                                                            "[by:Someone]\n"
                                                            "[00:01.00]only this"),
                                             0.0);

    QCOMPARE(r.lines.size(), 1);
    QCOMPARE(lineAt(r, 0).value(QStringLiteral("text")).toString(), QStringLiteral("only this"));
    QVERIFY(r.synced);
}

void TestLrcParser::setsSyncedForAnyMatchedLine() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]only"), 0.0);
    QVERIFY(r.synced);
}

void TestLrcParser::splitsTranslationOnTheFirstCaret() {
    const auto ln = lineAt(vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]Hello^Bonjour"), 0.0), 0);

    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("Hello"));
    QCOMPARE(ln.value(QStringLiteral("translation")).toString(), QStringLiteral("Bonjour"));
}

void TestLrcParser::translationIsEmptyWhenThereIsNoCaret() {
    const auto ln = lineAt(vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]Hello"), 0.0), 0);

    // The key is always present, never absent.
    QVERIFY(ln.contains(QStringLiteral("translation")));
    QVERIFY(ln.value(QStringLiteral("translation")).toString().isEmpty());
}

void TestLrcParser::onlyTheFirstCaretSplits() {
    const auto ln = lineAt(vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]a^b^c"), 0.0), 0);

    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("a"));
    QCOMPARE(ln.value(QStringLiteral("translation")).toString(), QStringLiteral("b^c"));
}

void TestLrcParser::translationIsTrimmed() {
    const auto ln = lineAt(vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]Hello   ^   Bonjour  "), 0.0), 0);

    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("Hello"));
    QCOMPARE(ln.value(QStringLiteral("translation")).toString(), QStringLiteral("Bonjour"));
}

void TestLrcParser::lastLineEndsAtFiveSecondsPastItsStartWhenTheTrackIsShorter() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]%1").arg(QLatin1String(TEN_TOKENS)), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 10);
    QCOMPARE(totalWordDuration(ws), 4750ll);
}

void TestLrcParser::lastLineEndsAtTheTotalDurationWhenTheTrackIsLonger() {
    const QString lrc = QStringLiteral("[00:10.00]%1").arg(QLatin1String(TEN_TOKENS));

    const auto    mid = vast::LrcParser::parseLrc(lrc, 16.0);
    QCOMPARE(totalWordDuration(wordsAt(mid, 0)), 5700ll);

    const auto longTrack = vast::LrcParser::parseLrc(lrc, 300.0);
    QCOMPARE(totalWordDuration(wordsAt(longTrack, 0)), 12000ll);
}

void TestLrcParser::aNonFinalLineEndsAtTheNextTimestamp() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]aa bb\n[00:01.00]cc"), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordTime(ws, 0), 0ll);
    QCOMPARE(wordDuration(ws, 0), 475ll);
    QCOMPARE(wordTime(ws, 1), 475ll);
    QCOMPARE(wordDuration(ws, 1), 475ll);
}

void TestLrcParser::anEmptyLineIsDroppedButStillBoundsThePreviousLine() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]aa bb\n[00:01.00]\n[00:02.00]cc"), 0.0);

    QCOMPARE(r.lines.size(), 2);
    QCOMPARE(r.wordLines.size(), 2);

    const auto ws = wordsAt(r, 0);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 475ll);
    QCOMPARE(wordDuration(ws, 1), 475ll);
}

void TestLrcParser::interpolatesWordDurationsBySyllableCount() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]go beautiful\n[00:03.00]next"), 0.0), 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordText(ws, 0), QStringLiteral("go"));
    QCOMPARE(wordDuration(ws, 0), 600ll);
    QCOMPARE(wordText(ws, 1), QStringLiteral("beautiful"));
    QCOMPARE(wordDuration(ws, 1), 1800ll);
}

void TestLrcParser::interpolatedWordTimesAreCumulative() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[00:03.00]next"), 0.0), 0);

    QCOMPARE(wordTime(ws, 0), 0ll);
    QCOMPARE(wordTime(ws, 1), wordTime(ws, 0) + wordDuration(ws, 0));
    QCOMPARE(wordTime(ws, 2), wordTime(ws, 1) + wordDuration(ws, 1));
    QCOMPARE(wordTime(ws, 2), 1900ll);
}

void TestLrcParser::capsInterpolatedDurationAtFallbackBudget() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[01:00.00]end"), 0.0), 0);

    QCOMPARE(ws.size(), 3);
    QVERIFY2(totalWordDuration(ws) <= 3 * vast::LrcParser::FALLBACK_MAX_MS_PER_WORD, "words spread past fallback budget");
    QCOMPARE(totalWordDuration(ws), 3600ll);
}

void TestLrcParser::stripsStrayAngleTagsBeforeInterpolating() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a <b> c\n[00:10.00]x"), 0.0), 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordText(ws, 0), QStringLiteral("a"));
    QCOMPARE(wordText(ws, 1), QStringLiteral("c"));
}

void TestLrcParser::wordSyncedIsFalseForInterpolatedLines() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[00:03.00]next"), 0.0);

    QVERIFY(r.synced);
    QVERIFY(!r.wordSynced);
    QCOMPARE(r.wordLines.size(), 2);
}

void TestLrcParser::anEmptyLineYieldsAnEmptyWordList() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]<b>\n[00:10.00]x"), 0.0);

    QCOMPARE(r.lines.size(), 2);
    QVERIFY(wordsAt(r, 0).isEmpty());
}

void TestLrcParser::parsesWordTagsIntoWords() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"), 0.0);
    const auto ws = wordsAt(r, 0);

    QVERIFY(r.wordSynced);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordText(ws, 0), QStringLiteral("Hello"));
    QCOMPARE(wordTime(ws, 0), 10500ll);
    QCOMPARE(wordText(ws, 1), QStringLiteral("world"));
    QCOMPARE(wordTime(ws, 1), 10900ll);
}

void TestLrcParser::wordTagDurationSpansToTheNextTag() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"), 0.0), 0);
    QCOMPARE(wordDuration(ws, 0), 400ll);
}

void TestLrcParser::capsTheLastWordAtMaxLastWordDurationMs() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"), 0.0), 0);
    QCOMPARE(wordDuration(ws, 1), vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

void TestLrcParser::wordTagsAcceptCentisecondAndMillisecondFractions() {
    const auto cs = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.05>a\n[00:30.00]x"), 0.0), 0);
    QCOMPARE(wordTime(cs, 0), 10050ll);

    const auto ms = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.005>a\n[00:30.00]x"), 0.0), 0);
    QCOMPARE(wordTime(ms, 0), 10005ll);
}

void TestLrcParser::duplicateWordTagTimesGiveZeroDuration() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]<00:10.00>A <00:10.00>B\n[00:30.00]e"), 0.0), 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 0ll);
    QCOMPARE(wordDuration(ws, 1), vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

void TestLrcParser::dropsWordTagsWithEmptyText() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]<00:10.00><00:10.50>\n[00:30.00]e"), 0.0);

    // The regex matched, so wordSynced is set even though nothing survived.
    QVERIFY(r.wordSynced);
    QVERIFY(wordsAt(r, 0).isEmpty());
}

void TestLrcParser::wordSyncedIsTrueWhenAnyLineCarriesTags() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello\n[00:20.00]plain untagged"), 0.0);

    QVERIFY(r.wordSynced);
    QCOMPARE(wordsAt(r, 0).size(), 1);
    // The untagged line still gets interpolated times.
    QCOMPARE(wordsAt(r, 1).size(), 2);
}

void TestLrcParser::stripsWordTagsFromDisplayLineText() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"), 0.0);

    QCOMPARE(lineAt(r, 0).value(QStringLiteral("text")).toString(), QStringLiteral("Hello world"));
}

void TestLrcParser::recordsCharSpansForWordSyncedAndInterpolatedLines() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hel<00:10.70>lo <00:10.90>world\n[00:12.00]foo bar\n[00:15.00]end"), 0.0);
    const auto w0 = wordsAt(r, 0);
    QCOMPARE(w0.size(), 3);
    QCOMPARE(w0.at(0).toMap().value(QStringLiteral("charStart")).toInt(), 0);
    QCOMPARE(w0.at(0).toMap().value(QStringLiteral("charLength")).toInt(), 3);
    QCOMPARE(w0.at(1).toMap().value(QStringLiteral("charStart")).toInt(), 3);
    QCOMPARE(w0.at(1).toMap().value(QStringLiteral("charLength")).toInt(), 2);
    QCOMPARE(w0.at(2).toMap().value(QStringLiteral("charStart")).toInt(), 6);
    QCOMPARE(w0.at(2).toMap().value(QStringLiteral("charLength")).toInt(), 5);

    const auto w1 = wordsAt(r, 1);
    QCOMPARE(w1.size(), 2);
    QCOMPARE(w1.at(0).toMap().value(QStringLiteral("charStart")).toInt(), 0);
    QCOMPARE(w1.at(0).toMap().value(QStringLiteral("charLength")).toInt(), 3);
    QCOMPARE(w1.at(1).toMap().value(QStringLiteral("charStart")).toInt(), 4);
    QCOMPARE(w1.at(1).toMap().value(QStringLiteral("charLength")).toInt(), 3);
}

void TestLrcParser::capsSingleTokenCjkLineAtFallbackMaxMsPerWord() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]君の名前を呼んだ\n[00:05.00]next"), 0.0), 0);

    QCOMPARE(ws.size(), 1);
    QCOMPARE(wordDuration(ws, 0), vast::LrcParser::FALLBACK_MAX_MS_PER_WORD);
}

void TestLrcParser::explicitClosingTagSetsWordEndAndFinalWordBypassesCap() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.00>Wait <00:10.40><00:12.00>scream<00:18.00>\n[00:25.00]next"), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordText(ws, 0), QStringLiteral("Wait"));
    QCOMPARE(ws.at(0).toMap().value(QStringLiteral("startTime")).toLongLong(), 10000ll);
    QCOMPARE(ws.at(0).toMap().value(QStringLiteral("endTime")).toLongLong(), 10400ll);
    QCOMPARE(wordDuration(ws, 0), 400ll);

    // Final word uses explicit closing tag (6000 ms > MAX_LAST_WORD_DURATION_MS).
    QCOMPARE(wordText(ws, 1), QStringLiteral("scream"));
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("startTime")).toLongLong(), 12000ll);
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("endTime")).toLongLong(), 18000ll);
    QCOMPARE(wordDuration(ws, 1), 6000ll);
    QVERIFY(wordDuration(ws, 1) > vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

void TestLrcParser::clampsWordEndBetweenStartAndNextWordStart() {
    // First closing tag overshoots next word's start; second closing tag precedes start.
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.00>a <00:15.00><00:11.00>b <00:09.00>\n[00:20.00]end"), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(ws.at(0).toMap().value(QStringLiteral("endTime")).toLongLong(), 11000ll);
    QCOMPARE(wordDuration(ws, 0), 1000ll);
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("endTime")).toLongLong(), 11000ll);
    QCOMPARE(wordDuration(ws, 1), 0ll);
}

void TestLrcParser::linesExposeWordsWithStartEndAndDerivedDuration() {
    const auto r     = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb\n[00:03.00]end"), 0.0);
    const auto words = lineAt(r, 0).value(QStringLiteral("words")).toList();

    QCOMPARE(words.size(), 2);
    for (const QVariant& v : words) {
        const auto m = v.toMap();
        QVERIFY(m.contains(QStringLiteral("startTime")));
        QVERIFY(m.contains(QStringLiteral("endTime")));
        QCOMPARE(m.value(QStringLiteral("duration")).toLongLong(), m.value(QStringLiteral("endTime")).toLongLong() - m.value(QStringLiteral("startTime")).toLongLong());
    }
}

void TestLrcParser::parseLyricsfileWithHeldWords() {
    const QString yaml = QStringLiteral("lines:\n"
                                        "  - text: \"quick hold\"\n"
                                        "    start_ms: 1000\n"
                                        "    end_ms: 4000\n"
                                        "    words:\n"
                                        "      - text: \"quick\"\n"
                                        "        start_ms: 1000\n"
                                        "        end_ms: 1150\n"
                                        "      - text: \"hold\"\n"
                                        "        start_ms: 1150\n"
                                        "        end_ms: 3650\n");
    const auto    r    = vast::LrcParser::parseLyricsfile(yaml, 10.0);
    const auto    ws   = wordsAt(r, 0);

    QVERIFY(r.synced);
    QVERIFY(r.wordSynced);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 150ll);
    QCOMPARE(wordDuration(ws, 1), 2500ll);
    QCOMPARE(lineAt(r, 0).value(QStringLiteral("words")).toList(), ws);
}

void TestLrcParser::parseLyricsfileLastWordUsesLineEndMs() {
    const QString yaml = QStringLiteral("lines:\n"
                                        "  - text: \"sing out\"\n"
                                        "    start_ms: 1000\n"
                                        "    end_ms: 9000\n"
                                        "    words:\n"
                                        "      - text: \"sing\"\n"
                                        "        start_ms: 1000\n"
                                        "      - text: \"out\"\n"
                                        "        start_ms: 1500\n");
    const auto    r    = vast::LrcParser::parseLyricsfile(yaml, 20.0);
    const auto    ws   = wordsAt(r, 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 500ll);
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("endTime")).toLongLong(), 9000ll);
    QCOMPARE(wordDuration(ws, 1), 7500ll);
}

void TestLrcParser::parseLyricsfileMissingEndMs() {
    const QString yaml = QStringLiteral("lines:\n"
                                        "  - text: \"first line\"\n"
                                        "    start_ms: 1000\n"
                                        "    words:\n"
                                        "      - text: \"first\"\n"
                                        "        start_ms: 1000\n"
                                        "      - text: \"line\"\n"
                                        "        start_ms: 1400\n"
                                        "  - text: \"next\"\n"
                                        "    start_ms: 15000\n");
    const auto    r    = vast::LrcParser::parseLyricsfile(yaml, 30.0);
    const auto    ws   = wordsAt(r, 0);

    QCOMPARE(r.lines.size(), 2);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 400ll);
    QCOMPARE(wordDuration(ws, 1), vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

void TestLrcParser::parseLyricsfileEmptyTextSeparatorLines() {
    const QString yaml = QStringLiteral("lines:\n"
                                        "  - text: \"hello\"\n"
                                        "    start_ms: 1000\n"
                                        "  - text: \"\"\n"
                                        "    start_ms: 3000\n"
                                        "  - text: \"world\"\n"
                                        "    start_ms: 8000\n");
    const auto    r    = vast::LrcParser::parseLyricsfile(yaml, 20.0);

    QCOMPARE(r.lines.size(), 2);
    QCOMPARE(r.wordLines.size(), 2);
    QCOMPARE(lineAt(r, 0).value(QStringLiteral("text")).toString(), QStringLiteral("hello"));
    QCOMPARE(lineAt(r, 1).value(QStringLiteral("text")).toString(), QStringLiteral("world"));
    QCOMPARE(r.wordLines.at(0).toMap().value(QStringLiteral("endTime")).toLongLong(), 3000ll);
}

void TestLrcParser::parseLyricsfileWordsNotMatchingLineText() {
    const QString yaml = QStringLiteral("lines:\n"
                                        "  - text: \"display line\"\n"
                                        "    start_ms: 1000\n"
                                        "    end_ms: 3000\n"
                                        "    words:\n"
                                        "      - text: \"foo\"\n"
                                        "        start_ms: 1000\n"
                                        "      - text: \"bar\"\n"
                                        "        start_ms: 2000\n");
    const auto    r    = vast::LrcParser::parseLyricsfile(yaml, 10.0);
    const auto    ws   = wordsAt(r, 0);

    QVERIFY(r.synced);
    QVERIFY(r.wordSynced);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(ws.at(0).toMap().value(QStringLiteral("charStart")).toInt(), 0);
    QCOMPARE(ws.at(0).toMap().value(QStringLiteral("charLength")).toInt(), 3);
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("charStart")).toInt(), 3);
    QCOMPARE(ws.at(1).toMap().value(QStringLiteral("charLength")).toInt(), 3);
}

void TestLrcParser::parseLyricsfileInvalidYamlFallsBackToSyncedLyrics() {
    const auto invalidResult = vast::LrcParser::parseLyricsfile(QStringLiteral("lines: [unterminated"), 10.0);
    QVERIFY(!invalidResult.synced);
    QVERIFY(invalidResult.lines.isEmpty());
    QVERIFY(invalidResult.wordLines.isEmpty());

    const auto fallback = vast::LrcParser::parseLrc(QStringLiteral("[00:01.00]fallback line"), 10.0);
    QVERIFY(fallback.synced);
    QCOMPARE(fallback.lines.size(), 1);
    QCOMPARE(lineAt(fallback, 0).value(QStringLiteral("text")).toString(), QStringLiteral("fallback line"));
}

void TestLrcParser::enhancedLrcHeldFinalWordCappedAtMaxLastWordDurationMs() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]<00:00.00>hold\n[00:20.00]next"), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 1);
    QCOMPARE(wordDuration(ws, 0), vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

void TestLrcParser::fallbackCommaCreatesPauseGapBeforeNextWord() {
    const auto withComma    = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]wait, now\n[00:05.00]end"), 0.0), 0);
    const auto withoutComma = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]wait now\n[00:05.00]end"), 0.0), 0);

    QCOMPARE(withComma.size(), 2);
    const qint64 commaWord0End   = withComma.at(0).toMap().value(QStringLiteral("endTime")).toLongLong();
    const qint64 commaWord1Start = withComma.at(1).toMap().value(QStringLiteral("startTime")).toLongLong();
    QVERIFY(commaWord1Start > commaWord0End);

    QCOMPARE(withoutComma.size(), 2);
    const qint64 plainWord0End   = withoutComma.at(0).toMap().value(QStringLiteral("endTime")).toLongLong();
    const qint64 plainWord1Start = withoutComma.at(1).toMap().value(QStringLiteral("startTime")).toLongLong();
    QCOMPARE(plainWord1Start, plainWord0End);
}

void TestLrcParser::outOfOrderLineTimestampsClampWordDurationToZero() {
    // Malformed input: out-of-order lines clamp duration to zero.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:20.00]x\n[00:10.00]y"), 0.0), 0);

    QCOMPARE(ws.size(), 1);
    QCOMPARE(wordTime(ws, 0), 20000ll);
    QCOMPARE(wordDuration(ws, 0), 0ll);
}

void TestLrcParser::parsePlainMarksEverythingUntimed() {
    const auto r  = vast::LrcParser::parsePlain(QStringLiteral("hello world"));
    const auto ws = wordsAt(r, 0);

    QCOMPARE(lineAt(r, 0).value(QStringLiteral("time")).toLongLong(), -1ll);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordTime(ws, 0), -1ll);
    QCOMPARE(wordDuration(ws, 0), 0ll);
}

void TestLrcParser::parsePlainLeavesSyncedAndWordSyncedFalse() {
    const auto r = vast::LrcParser::parsePlain(QStringLiteral("a\nb\nc"));

    QCOMPARE(r.lines.size(), 3);
    QVERIFY(!r.synced);
    QVERIFY(!r.wordSynced);
}

void TestLrcParser::parsePlainSkipsBlankLines() {
    const auto r = vast::LrcParser::parsePlain(QStringLiteral("a\n\n\nb"));
    QCOMPARE(r.lines.size(), 2);
}

void TestLrcParser::parsePlainSplitsTranslationOnTheFirstCaret() {
    const auto ln = lineAt(vast::LrcParser::parsePlain(QStringLiteral("Hello^Bonjour^again")), 0);

    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("Hello"));
    QCOMPARE(ln.value(QStringLiteral("translation")).toString(), QStringLiteral("Bonjour^again"));
}

void TestLrcParser::parsePlainSplitsWordsOnSpaces() {
    const auto ws = wordsAt(vast::LrcParser::parsePlain(QStringLiteral("aa bb  cc")), 0);

    QCOMPARE(ws.size(), 3);
    QCOMPARE(wordText(ws, 0), QStringLiteral("aa"));
    QCOMPARE(wordText(ws, 1), QStringLiteral("bb"));
    QCOMPARE(wordText(ws, 2), QStringLiteral("cc"));
}

void TestLrcParser::parsePlainTreatsLrcTagsAsLiteralText() {
    const auto ln = lineAt(vast::LrcParser::parsePlain(QStringLiteral("[00:10.00]hello")), 0);
    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("[00:10.00]hello"));
}

void TestLrcParser::parsePlainOnEmptyInputYieldsEmptyLists() {
    const auto r = vast::LrcParser::parsePlain(QString());

    QVERIFY(r.lines.isEmpty());
    QVERIFY(r.wordLines.isEmpty());
}

void TestLrcParser::linesAndWordLinesStayIndexAligned() {
    const QList<QString> lrcs{
        QStringLiteral("[00:00.00]a bb\n[00:01.00]\n[00:02.00]c d"),
        QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"),
    };
    for (const QString& lrc : lrcs) {
        const auto r = vast::LrcParser::parseLrc(lrc, 0.0);
        QCOMPARE(r.lines.size(), r.wordLines.size());
    }

    const auto p = vast::LrcParser::parsePlain(QStringLiteral("a b\nc d e"));
    QCOMPARE(p.lines.size(), p.wordLines.size());
}

QTEST_GUILESS_MAIN(TestLrcParser)
#include "tst_lrcparser.moc"
