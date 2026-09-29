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

    // Ten tokens: the 10 * 800 cap does not mask a 5000 ms gap.
    const char* const TEN_TOKENS = "a bb ccc dddd eeeee f g h i j";

} // namespace

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

    void interpolatesWordDurationsByCharacterLength();
    void interpolatedWordTimesAreCumulative();
    void capsInterpolatedDurationAtTokensTimes800();
    void stripsStrayAngleTagsBeforeInterpolating();
    void wordSyncedIsFalseForInterpolatedLines();
    void anEmptyLineYieldsAnEmptyWordList();

    void parsesWordTagsIntoWords();
    void wordTagDurationSpansToTheNextTag();
    void capsTheLastWordAt1500ms();
    void wordTagsAcceptCentisecondAndMillisecondFractions();
    void duplicateWordTagTimesGiveZeroDuration();
    void dropsWordTagsWithEmptyText();
    void wordSyncedIsTrueWhenAnyLineCarriesTags();

    void outOfOrderLineTimestampsYieldANegativeWordDuration();

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
    // The line regex requires \d{2,3} after the dot.
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10.5]x"), 0.0);
    QVERIFY(r.lines.isEmpty());
}

void TestLrcParser::rejectsTimestampWithoutAFraction() {
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:10]x"), 0.0);
    QVERIFY(r.lines.isEmpty());
}

void TestLrcParser::rejectsSingleDigitMinutes() {
    // \d{2} is required for minutes as well as seconds.
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
    // lineEnd = max(lineStart + 5000, totalMs) = 15000, so the gap is 5000.
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]%1").arg(QLatin1String(TEN_TOKENS)), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 10);
    // 5000 less 3 ms of per-word truncation.
    QCOMPARE(totalWordDuration(ws), 4997ll);
}

void TestLrcParser::lastLineEndsAtTheTotalDurationWhenTheTrackIsLonger() {
    const QString lrc = QStringLiteral("[00:10.00]%1").arg(QLatin1String(TEN_TOKENS));

    // totalMs beats the +5000 floor: max(15000, 16000) = 16000, gap 6000.
    const auto mid = vast::LrcParser::parseLrc(lrc, 16.0);
    QCOMPARE(totalWordDuration(wordsAt(mid, 0)), 6000ll);

    // A far longer track clamps the gap to tokens * 800.
    const auto longTrack = vast::LrcParser::parseLrc(lrc, 300.0);
    QCOMPARE(totalWordDuration(wordsAt(longTrack, 0)), 7997ll);
}

void TestLrcParser::aNonFinalLineEndsAtTheNextTimestamp() {
    const auto r  = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]aa bb\n[00:01.00]cc"), 0.0);
    const auto ws = wordsAt(r, 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordTime(ws, 0), 0ll);
    QCOMPARE(wordDuration(ws, 0), 500ll);
    QCOMPARE(wordTime(ws, 1), 500ll);
    QCOMPARE(wordDuration(ws, 1), 500ll);
}

void TestLrcParser::anEmptyLineIsDroppedButStillBoundsThePreviousLine() {
    // lineEnd is computed before the empty-line continue, so line 0 still ends at 1000, not 2000.
    const auto r = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]aa bb\n[00:01.00]\n[00:02.00]cc"), 0.0);

    QCOMPARE(r.lines.size(), 2);
    QCOMPARE(r.wordLines.size(), 2);

    const auto ws = wordsAt(r, 0);
    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 500ll);
    QCOMPARE(wordDuration(ws, 1), 500ll);
}

void TestLrcParser::interpolatesWordDurationsByCharacterLength() {
    // totalWeight 9, gap min(3000, 3*800) = 2400, shares (len+1)/9 * 2400.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[00:03.00]next"), 0.0), 0);

    QCOMPARE(ws.size(), 3);
    QCOMPARE(wordText(ws, 0), QStringLiteral("a"));
    QCOMPARE(wordDuration(ws, 0), 533ll);
    QCOMPARE(wordText(ws, 1), QStringLiteral("bb"));
    QCOMPARE(wordDuration(ws, 1), 800ll);
    QCOMPARE(wordText(ws, 2), QStringLiteral("ccc"));
    QCOMPARE(wordDuration(ws, 2), 1066ll);
}

void TestLrcParser::interpolatedWordTimesAreCumulative() {
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[00:03.00]next"), 0.0), 0);

    QCOMPARE(wordTime(ws, 0), 0ll);
    QCOMPARE(wordTime(ws, 1), wordTime(ws, 0) + wordDuration(ws, 0));
    QCOMPARE(wordTime(ws, 2), wordTime(ws, 1) + wordDuration(ws, 1));
    QCOMPARE(wordTime(ws, 2), 1333ll);
}

void TestLrcParser::capsInterpolatedDurationAtTokensTimes800() {
    // A 60 s line for three tokens: the gap is clamped to 3 * 800 = 2400.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]a bb ccc\n[01:00.00]end"), 0.0), 0);

    QCOMPARE(ws.size(), 3);
    QVERIFY2(totalWordDuration(ws) <= 3 * 800, "words spread past tokens * 800");
    // Truncation loses 1 ms of the 2400 budget; nothing is invented beyond it.
    QCOMPARE(totalWordDuration(ws), 2399ll);
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
    // Every token is stripped, so interpolateWords returns {}.
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

void TestLrcParser::capsTheLastWordAt1500ms() {
    // The next line is at 30000, so an uncapped duration would be 19100 ms.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.50]<00:10.50>Hello <00:10.90>world\n[00:30.00]end"), 0.0), 0);
    QCOMPARE(wordDuration(ws, 1), 1500ll);
}

void TestLrcParser::wordTagsAcceptCentisecondAndMillisecondFractions() {
    const auto cs = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.05>a\n[00:30.00]x"), 0.0), 0);
    QCOMPARE(wordTime(cs, 0), 10050ll);

    const auto ms = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.005>a\n[00:30.00]x"), 0.0), 0);
    QCOMPARE(wordTime(ms, 0), 10005ll);
}

void TestLrcParser::duplicateWordTagTimesGiveZeroDuration() {
    // qMax<qint64>(0, nextT - t) floors the zero-length span at 0.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]<00:10.00>A <00:10.00>B\n[00:30.00]e"), 0.0), 0);

    QCOMPARE(ws.size(), 2);
    QCOMPARE(wordDuration(ws, 0), 0ll);
    QCOMPARE(wordDuration(ws, 1), 1500ll);
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

void TestLrcParser::outOfOrderLineTimestampsYieldANegativeWordDuration() {
    // Malformed input: out-of-order lines give a negative duration.
    const auto ws = wordsAt(vast::LrcParser::parseLrc(QStringLiteral("[00:20.00]x\n[00:10.00]y"), 0.0), 0);

    QCOMPARE(ws.size(), 1);
    QCOMPARE(wordTime(ws, 0), 20000ll);
    QCOMPARE(wordDuration(ws, 0), -10000ll);
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
    // No tag handling on this path: the bracket is part of the lyric.
    const auto ln = lineAt(vast::LrcParser::parsePlain(QStringLiteral("[00:10.00]hello")), 0);
    QCOMPARE(ln.value(QStringLiteral("text")).toString(), QStringLiteral("[00:10.00]hello"));
}

void TestLrcParser::parsePlainOnEmptyInputYieldsEmptyLists() {
    const auto r = vast::LrcParser::parsePlain(QString());

    QVERIFY(r.lines.isEmpty());
    QVERIFY(r.wordLines.isEmpty());
}

void TestLrcParser::linesAndWordLinesStayIndexAligned() {
    // rebuildBoundaries indexes mWordLines by lineIndex, so the two stay aligned.
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
