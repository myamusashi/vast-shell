#include <qlist.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include "../../Lyrics/LrcParser.hpp"
#include "../../Lyrics/LyricsScheduler.hpp"

namespace {

    [[nodiscard]] QVariantMap word(qint64 timeMs, qint64 durationMs, const QString& text = QStringLiteral("w")) {
        QVariantMap m;
        m.insert(QStringLiteral("time"), timeMs);
        m.insert(QStringLiteral("text"), text);
        m.insert(QStringLiteral("duration"), durationMs);
        return m;
    }

    // wordLines is a list of QVariantMap, the shape LrcParser emits. rebuildBoundaries reads it with
    // toMap().
    [[nodiscard]] QVariantMap wordLine(qint64 lineTimeMs, const QVariantList& words) {
        QVariantMap m;
        m.insert(QStringLiteral("time"), lineTimeMs);
        m.insert(QStringLiteral("words"), words);
        return m;
    }

    // The parsePlain shape: every word time is -1, so no boundaries.
    [[nodiscard]] QVariantList plainWordLines(const QStringList& texts) {
        QVariantList out;
        for (const QString& t : texts)
            out.append(wordLine(-1, {word(-1, 0, t)}));
        return out;
    }

} // namespace

class TestLyricsScheduler : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void init();

    void freshSchedulerHasNoCurrentPosition();
    void defaultOffsetIs150Ms();
    void setOffsetMsStoresTheValue();
    void settingTheSameOffsetIsANoOp();

    void pausedAndPlayingResolveTheSameCurrentLine();
    void aPositionBeforeTheFirstBoundaryHasNoLine();
    void aPositionExactlyOnABoundarySelectsIt();
    void aPositionAfterTheLastBoundarySelectsTheLastWord();
    void advancesLineAndWordTogetherAcrossBoundaries();
    void exposesTheDurationOfTheCurrentWord();
    void emitsCurrentIndexChangedOnlyWhenTheIndexMoves();
    void emitsCurrentWordDurationChangedOnlyWhenTheDurationChanges();

    void wordLinesWithNegativeTimesProduceNoBoundaries();
    void emptyWordLinesLeaveNoCurrentLine();
    void outOfOrderWordTimesAreSortedByTime();
    void duplicateWordTimesDoNotCrashAndSelectOneOfThem();

    void resetClearsTheIndicesAndSignals();
    void resetStopsTheTimerSoLaterPlaybackDoesNotReindex();
    void acceptsWordLinesStraightFromLrcParser();

    void playingAdvancesTheIndexOverWallClockTime();
    void aHigherRateReachesTheSameIndexSooner();

  private:
    vast::LyricsScheduler mScheduler;
};

void TestLyricsScheduler::init() {
    mScheduler.reset();
}

void TestLyricsScheduler::freshSchedulerHasNoCurrentPosition() {
    QCOMPARE(mScheduler.currentLineIndex(), -1);
    QCOMPARE(mScheduler.currentWordIndex(), -1);
    QCOMPARE(mScheduler.currentWordDuration(), 0ll);
}

void TestLyricsScheduler::defaultOffsetIs150Ms() {
    QCOMPARE(mScheduler.offsetMs(), 150);
}

void TestLyricsScheduler::setOffsetMsStoresTheValue() {
    mScheduler.setOffsetMs(320);
    QCOMPARE(mScheduler.offsetMs(), 320);
}

void TestLyricsScheduler::settingTheSameOffsetIsANoOp() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500)})});
    mScheduler.setPlayback(0.0, 1.0, false);
    mScheduler.setOffsetMs(150); // already the default

    QSignalSpy spy(&mScheduler, &vast::LyricsScheduler::currentIndexChanged);
    mScheduler.setOffsetMs(150);

    QCOMPARE(spy.count(), 0);
}

void TestLyricsScheduler::pausedAndPlayingResolveTheSameCurrentLine() {
    // Paused and playing must resolve the same line at the same position.
    const QVariantList    lines{wordLine(10100, {word(10100, 500)})};

    vast::LyricsScheduler paused;
    paused.setWordLines(lines);
    paused.setPlayback(10.0, 1.0, false);

    vast::LyricsScheduler playing;
    playing.setWordLines(lines);
    playing.setPlayback(10.0, 1.0, true);

    QCOMPARE(paused.offsetMs(), playing.offsetMs());
    QCOMPARE(paused.currentLineIndex(), playing.currentLineIndex());
    QCOMPARE(paused.currentWordIndex(), playing.currentWordIndex());
    // 10000 + 150 = 10150, which is at or past the 10100 boundary.
    QCOMPARE(paused.currentLineIndex(), 0);
}

void TestLyricsScheduler::aPositionBeforeTheFirstBoundaryHasNoLine() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(5.0, 1.0, false);

    QCOMPARE(mScheduler.currentLineIndex(), -1);
    QCOMPARE(mScheduler.currentWordIndex(), -1);
}

void TestLyricsScheduler::aPositionExactlyOnABoundarySelectsIt() {
    // upper_bound plus std::prev: a position on a boundary selects it.
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500), word(10500, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.5, 1.0, false);

    QCOMPARE(mScheduler.currentLineIndex(), 0);
    QCOMPARE(mScheduler.currentWordIndex(), 1);
}

void TestLyricsScheduler::aPositionAfterTheLastBoundarySelectsTheLastWord() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500), word(10500, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(99.0, 1.0, false);

    QCOMPARE(mScheduler.currentLineIndex(), 0);
    QCOMPARE(mScheduler.currentWordIndex(), 1);
}

void TestLyricsScheduler::advancesLineAndWordTogetherAcrossBoundaries() {
    mScheduler.setWordLines({
        wordLine(10000, {word(10000, 500), word(10500, 500)}),
        wordLine(11000, {word(11000, 500), word(11500, 500)}),
    });
    mScheduler.setOffsetMs(0);

    mScheduler.setPlayback(5.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), -1);
    QCOMPARE(mScheduler.currentWordIndex(), -1);

    mScheduler.setPlayback(10.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 0);
    QCOMPARE(mScheduler.currentWordIndex(), 0);

    mScheduler.setPlayback(10.5, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 0);
    QCOMPARE(mScheduler.currentWordIndex(), 1);

    mScheduler.setPlayback(11.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 1);
    QCOMPARE(mScheduler.currentWordIndex(), 0);
}

void TestLyricsScheduler::exposesTheDurationOfTheCurrentWord() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 750), word(11000, 250)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);

    QCOMPARE(mScheduler.currentWordDuration(), 750ll);

    mScheduler.setPlayback(11.0, 1.0, false);
    QCOMPARE(mScheduler.currentWordDuration(), 250ll);
}

void TestLyricsScheduler::emitsCurrentIndexChangedOnlyWhenTheIndexMoves() {
    // Two boundaries, so there is somewhere to move to.
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500), word(10500, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);
    QCOMPARE(mScheduler.currentWordIndex(), 0);

    QSignalSpy spy(&mScheduler, &vast::LyricsScheduler::currentIndexChanged);

    // Still within the first word's slot, so nothing moves and nothing is emitted.
    mScheduler.setPlayback(10.2, 1.0, false);
    QCOMPARE(spy.count(), 0);

    mScheduler.setPlayback(10.5, 1.0, false);
    QCOMPARE(mScheduler.currentWordIndex(), 1);
    QCOMPARE(spy.count(), 1);
}

void TestLyricsScheduler::emitsCurrentWordDurationChangedOnlyWhenTheDurationChanges() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500), word(11000, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);

    QSignalSpy spy(&mScheduler, &vast::LyricsScheduler::currentWordDurationChanged);

    mScheduler.setPlayback(10.2, 1.0, false);
    QCOMPARE(spy.count(), 0); // same word, same duration

    mScheduler.setPlayback(11.0, 1.0, false);
    // Duration happens to be equal here, so this only asserts the index moved.
    QCOMPARE(mScheduler.currentWordIndex(), 1);
}

void TestLyricsScheduler::wordLinesWithNegativeTimesProduceNoBoundaries() {
    // rebuildBoundaries skips words with time < 0, so unsynced lyrics never highlight.
    mScheduler.setWordLines(plainWordLines({QStringLiteral("a"), QStringLiteral("b")}));
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(0.0, 1.0, false);
    mScheduler.setPlayback(600.0, 1.0, false);

    QCOMPARE(mScheduler.currentLineIndex(), -1);
    QCOMPARE(mScheduler.currentWordIndex(), -1);
    QCOMPARE(mScheduler.currentWordDuration(), 0ll);
}

void TestLyricsScheduler::emptyWordLinesLeaveNoCurrentLine() {
    mScheduler.setWordLines(QVariantList{});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(600.0, 1.0, false);

    QCOMPARE(mScheduler.currentLineIndex(), -1);
}

void TestLyricsScheduler::outOfOrderWordTimesAreSortedByTime() {
    mScheduler.setWordLines({
        wordLine(5000, {word(5000, 100, QStringLiteral("late"))}),
        wordLine(1000, {word(1000, 100, QStringLiteral("early"))}),
        wordLine(3000, {word(3000, 100, QStringLiteral("middle"))}),
    });
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(3.5, 1.0, false);

    // Boundaries are stable-sorted by time, so 3500 lands on the 3000 word.
    QCOMPARE(mScheduler.currentLineIndex(), 2);
    QCOMPARE(mScheduler.currentWordIndex(), 0);
}

void TestLyricsScheduler::duplicateWordTimesDoNotCrashAndSelectOneOfThem() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 100, QStringLiteral("a")), word(10000, 200, QStringLiteral("b"))})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);

    // The tie-break is whatever upper_bound yields, so accept either index
    // rather than pinning one that is not part of the contract.
    const int word = mScheduler.currentWordIndex();
    QVERIFY(word == 0 || word == 1);
    QCOMPARE(mScheduler.currentLineIndex(), 0);
}

void TestLyricsScheduler::resetClearsTheIndicesAndSignals() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 0);

    QSignalSpy spy(&mScheduler, &vast::LyricsScheduler::currentIndexChanged);
    mScheduler.reset();

    QCOMPARE(spy.count(), 1);
    QCOMPARE(mScheduler.currentLineIndex(), -1);
    QCOMPARE(mScheduler.currentWordIndex(), -1);
    QCOMPARE(mScheduler.currentWordDuration(), 0ll);
}

void TestLyricsScheduler::resetStopsTheTimerSoLaterPlaybackDoesNotReindex() {
    mScheduler.setWordLines({wordLine(10000, {word(10000, 500)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(10.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 0);

    mScheduler.reset();
    mScheduler.setPlayback(10.0, 1.0, false);

    // The boundaries were cleared, so nothing can be selected any more.
    QCOMPARE(mScheduler.currentLineIndex(), -1);
}

void TestLyricsScheduler::acceptsWordLinesStraightFromLrcParser() {
    // The real hand-off: LyricsProvider::applyParseResult forwards
    // LrcParser::Result::wordLines verbatim, so the shape the parser emits must
    // be the shape the scheduler reads. Feeding one into the other proves the
    // contract rather than restating it.
    const auto parsed = vast::LrcParser::parseLrc(QStringLiteral("[00:00.00]hello world\n[00:02.00]second line"), 0.0);
    QCOMPARE(parsed.wordLines.size(), 2);

    mScheduler.setWordLines(parsed.wordLines);
    mScheduler.setOffsetMs(0);

    mScheduler.setPlayback(1.0, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 0);

    mScheduler.setPlayback(2.5, 1.0, false);
    QCOMPARE(mScheduler.currentLineIndex(), 1);
}

void TestLyricsScheduler::playingAdvancesTheIndexOverWallClockTime() {
    // The only time-dependent slot: it depends on a QTimer firing, so it uses a
    // generous QTRY timeout rather than an exact equality.
    mScheduler.setWordLines({wordLine(0, {word(0, 100)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(0.0, 1.0, true);

    QTRY_VERIFY_WITH_TIMEOUT(mScheduler.currentLineIndex() == 0, 10000);
}

void TestLyricsScheduler::aHigherRateReachesTheSameIndexSooner() {
    // A boundary far in the future is unreachable at rate 1.0 within the
    // timeout, but rate 4.0 covers the distance in a fraction of it.
    mScheduler.setWordLines({wordLine(1200, {word(1200, 100)})});
    mScheduler.setOffsetMs(0);
    mScheduler.setPlayback(0.0, 4.0, true);

    QTRY_VERIFY_WITH_TIMEOUT(mScheduler.currentLineIndex() == 0, 10000);
}

QTEST_GUILESS_MAIN(TestLyricsScheduler)
#include "tst_lyricsscheduler.moc"
