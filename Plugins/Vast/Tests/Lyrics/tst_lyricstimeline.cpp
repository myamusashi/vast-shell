#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include "../../Lyrics/LrcParser.hpp"
#include "../../Lyrics/LyricsTimeline.hpp"

namespace {
    [[nodiscard]] QVariantMap makeWord(qint64 startMs, qint64 endMs, qsizetype charStart, qsizetype charLength, const QString& text) {
        QVariantMap m;
        m.insert(QStringLiteral("time"), startMs);
        m.insert(QStringLiteral("startTime"), startMs);
        m.insert(QStringLiteral("endTime"), endMs);
        m.insert(QStringLiteral("duration"), endMs - startMs);
        m.insert(QStringLiteral("charStart"), charStart);
        m.insert(QStringLiteral("charLength"), charLength);
        m.insert(QStringLiteral("text"), text);
        return m;
    }
} // namespace

class TestLyricsTimeline : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void emptyInputsProduceEmptyTimeline();
    void animatesEachWordByItsOwnStartAndEndDuration();
    void doesNotCarryHighlightAcrossGapsBetweenWords();
    void backwardSeekUpdatesActiveWordAndProgress();
    void handlesZeroDurationWordsWithoutDivisionByZero();
    void clampsEndTimeBetweenStartAndNextWordStart();
    void integratesWithLrcParserFinalWordCapAndClosingTags();
};

void TestLyricsTimeline::emptyInputsProduceEmptyTimeline() {
    vast::LyricsTimeline tl;
    tl.rebuild(QString(), {});
    QVERIFY(tl.isEmpty());

    tl.rebuild(QStringLiteral("hello"), {});
    QVERIFY(tl.isEmpty());
}

void TestLyricsTimeline::animatesEachWordByItsOwnStartAndEndDuration() {
    vast::LyricsTimeline tl;
    tl.rebuild(QStringLiteral("go yeah"),
               {
                   makeWord(1000, 1200, 0, 2, QStringLiteral("go")),
                   makeWord(1200, 3200, 3, 4, QStringLiteral("yeah")),
               });

    QCOMPARE(tl.wordCount(), 2);

    tl.updatePosition(999);
    QCOMPARE(tl.activeWordIndex(), -1);
    QCOMPARE(tl.activeWordProgress(999), 0.0);

    // Quick 200 ms word at midpoint.
    tl.updatePosition(1100);
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(1100), 0.5);

    // Held 2000 ms word at 25% and 75%.
    tl.updatePosition(1700);
    QCOMPARE(tl.activeWordIndex(), 1);
    QCOMPARE(tl.activeWordProgress(1700), 0.25);

    tl.updatePosition(2700);
    QCOMPARE(tl.activeWordIndex(), 1);
    QCOMPARE(tl.activeWordProgress(2700), 0.75);

    tl.updatePosition(3200);
    QCOMPARE(tl.activeWordIndex(), 1);
    QCOMPARE(tl.activeWordProgress(3200), 1.0);
}

void TestLyricsTimeline::doesNotCarryHighlightAcrossGapsBetweenWords() {
    vast::LyricsTimeline tl;
    tl.rebuild(QStringLiteral("wait now"),
               {
                   makeWord(1000, 1400, 0, 4, QStringLiteral("wait")),
                   makeWord(3000, 3500, 5, 3, QStringLiteral("now")),
               });

    // Mid-gap at 2200 ms and end of gap at 2999 ms: word 0 stays 1.0, word 1 has not started.
    tl.updatePosition(2200);
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(2200), 1.0);
    QCOMPARE(tl.wordProgressAt(1, 2200), 0.0);

    tl.updatePosition(2999);
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(2999), 1.0);
    QCOMPARE(tl.wordProgressAt(1, 2999), 0.0);

    // At 3000 ms, word 1 begins at progress 0.0.
    QVERIFY(tl.updatePosition(3000));
    QCOMPARE(tl.activeWordIndex(), 1);
    QCOMPARE(tl.activeWordProgress(3000), 0.0);
}

void TestLyricsTimeline::backwardSeekUpdatesActiveWordAndProgress() {
    vast::LyricsTimeline tl;
    tl.rebuild(QStringLiteral("one two three"),
               {
                   makeWord(1000, 1500, 0, 3, QStringLiteral("one")),
                   makeWord(2000, 2500, 4, 3, QStringLiteral("two")),
                   makeWord(3000, 4000, 8, 5, QStringLiteral("three")),
               });

    tl.updatePosition(3800);
    QCOMPARE(tl.activeWordIndex(), 2);
    QCOMPARE(tl.activeWordProgress(3800), 0.8);

    // Seek backward within the same word.
    QVERIFY(tl.updatePosition(3200));
    QCOMPARE(tl.activeWordIndex(), 2);
    QCOMPARE(tl.activeWordProgress(3200), 0.2);

    // Seek forward into a gap, then backward into word 0.
    tl.updatePosition(2800);
    QVERIFY(tl.updatePosition(1250));
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(1250), 0.5);

    // Seek backward before the first word.
    QVERIFY(tl.updatePosition(500));
    QCOMPARE(tl.activeWordIndex(), -1);
    QCOMPARE(tl.activeWordProgress(500), 0.0);
}

void TestLyricsTimeline::handlesZeroDurationWordsWithoutDivisionByZero() {
    vast::LyricsTimeline tl;
    tl.rebuild(QStringLiteral("snap word"),
               {
                   makeWord(1000, 1000, 0, 4, QStringLiteral("snap")),
                   makeWord(2000, 2500, 5, 4, QStringLiteral("word")),
               });

    tl.updatePosition(999);
    QCOMPARE(tl.activeWordIndex(), -1);
    QCOMPARE(tl.activeWordProgress(999), 0.0);

    tl.updatePosition(1000);
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(1000), 1.0);

    tl.updatePosition(1500);
    QCOMPARE(tl.activeWordIndex(), 0);
    QCOMPARE(tl.activeWordProgress(1500), 1.0);
}

void TestLyricsTimeline::clampsEndTimeBetweenStartAndNextWordStart() {
    vast::LyricsTimeline tl;
    tl.rebuild(QStringLiteral("a b"),
               {
                   makeWord(1000, 5000, 0, 1, QStringLiteral("a")),
                   makeWord(2000, 1500, 2, 1, QStringLiteral("b")),
               });

    QCOMPARE(tl.wordAt(0).endMs, 2000ll);
    QCOMPARE(tl.wordAt(1).endMs, 2000ll);
    QCOMPARE(tl.wordProgressAt(0, 1500), 0.5);
    QCOMPARE(tl.wordProgressAt(1, 2000), 1.0);
}

void TestLyricsTimeline::integratesWithLrcParserFinalWordCapAndClosingTags() {
    const auto           uncapped = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.00>hold<00:13.00>\n[00:20.00]next"), 0.0);
    const auto           capped   = vast::LrcParser::parseLrc(QStringLiteral("[00:10.00]<00:10.00>hold\n[00:20.00]next"), 0.0);

    vast::LyricsTimeline tlUncapped;
    tlUncapped.rebuild(uncapped.lines.at(0).toMap().value(QStringLiteral("text")).toString(), uncapped.lines.at(0).toMap().value(QStringLiteral("words")).toList());
    QCOMPARE(tlUncapped.wordAt(0).endMs, 13000ll);

    vast::LyricsTimeline tlCapped;
    tlCapped.rebuild(capped.lines.at(0).toMap().value(QStringLiteral("text")).toString(), capped.lines.at(0).toMap().value(QStringLiteral("words")).toList());
    QCOMPARE(tlCapped.wordAt(0).endMs, 10000ll + vast::LrcParser::MAX_LAST_WORD_DURATION_MS);
}

QTEST_GUILESS_MAIN(TestLyricsTimeline)
#include "tst_lyricstimeline.moc"
