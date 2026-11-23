#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qstring.h>
#include <qtest.h>

#include "../../Lyrics/LyricsSelector.hpp"

namespace {

    const QString             WORD_SYNCED_YAML = QStringLiteral("lines:\n"
                                                                            "  - text: \"hello world\"\n"
                                                                            "    start_ms: 1000\n"
                                                                            "    end_ms: 2000\n"
                                                                            "    words:\n"
                                                                            "      - text: \"hello\"\n"
                                                                            "        start_ms: 1000\n"
                                                                            "        end_ms: 1400\n"
                                                                            "      - text: \"world\"\n"
                                                                            "        start_ms: 1500\n"
                                                                            "        end_ms: 2000\n");

    const QString             LINE_ONLY_YAML = QStringLiteral("lines:\n"
                                                                          "  - text: \"hello world\"\n"
                                                                          "    start_ms: 1000\n"
                                                                          "    end_ms: 2000\n");

    const QString             ENHANCED_LRC = QStringLiteral("[00:01.00]<00:01.00>hello <00:01.50>world<00:02.00>\n");
    const QString             LINE_LRC     = QStringLiteral("[00:01.00]hello world\n");
    const QString             PLAIN_LYRICS = QStringLiteral("hello world\n");

    [[nodiscard]] QJsonObject makeRecord(int id, const QString& trackName, const QString& artistName, double duration, const QString& lyricsfile, const QString& syncedLyrics,
                                         const QString& plainLyrics) {
        QJsonObject obj;
        obj.insert(QStringLiteral("id"), id);
        obj.insert(QStringLiteral("trackName"), trackName);
        obj.insert(QStringLiteral("artistName"), artistName);
        obj.insert(QStringLiteral("duration"), duration);
        if (!lyricsfile.isEmpty())
            obj.insert(QStringLiteral("lyricsfile"), lyricsfile);
        if (!syncedLyrics.isEmpty())
            obj.insert(QStringLiteral("syncedLyrics"), syncedLyrics);
        if (!plainLyrics.isEmpty())
            obj.insert(QStringLiteral("plainLyrics"), plainLyrics);
        return obj;
    }

} // namespace

class TestLyricsSelector : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void parsePayloadPrefersWordSyncedLyricsfile();
    void parsePayloadPrefersEnhancedLrcOverLineOnlyLyricsfile();
    void parsePayloadFallsBackToLineSyncedThenPlain();
    void parsePayloadReturnsNulloptForEmptyRecord();

    void selectBestCandidatePrefersWordSyncedAmongDuplicateTracks();
    void selectBestCandidatePrefersEnhancedLrcOverLineSynced();
    void selectBestCandidateRejectsFarDurationRemixEvenIfWordSynced();
    void selectBestCandidatePrefersExactArtistAndTitleOverWordSyncedCover();
    void selectBestCandidatePrefersSyncedOverPlainWithinMaxDurationDiff();
    void selectBestCandidateBreaksTiesByCloserDuration();
    void selectBestCandidateHandlesUnknownRequestedDuration();
    void selectBestCandidateSkipsInstrumentalAndInvalidEntries();
};

void TestLyricsSelector::parsePayloadPrefersWordSyncedLyricsfile() {
    const QJsonObject payload = makeRecord(1, QStringLiteral("Song"), QStringLiteral("Artist"), 180.0, WORD_SYNCED_YAML, LINE_LRC, PLAIN_LYRICS);
    const auto        parsed  = vast::LyricsSelector::parsePayload(payload, 180.0);

    QVERIFY(parsed.has_value());
    QVERIFY(parsed->synced);
    QVERIFY(parsed->wordSynced);
    QCOMPARE(parsed->wordLines.size(), 1);
}

void TestLyricsSelector::parsePayloadPrefersEnhancedLrcOverLineOnlyLyricsfile() {
    const QJsonObject payload = makeRecord(1, QStringLiteral("Song"), QStringLiteral("Artist"), 180.0, LINE_ONLY_YAML, ENHANCED_LRC, PLAIN_LYRICS);
    const auto        parsed  = vast::LyricsSelector::parsePayload(payload, 180.0);

    QVERIFY(parsed.has_value());
    QVERIFY(parsed->synced);
    QVERIFY(parsed->wordSynced);
}

void TestLyricsSelector::parsePayloadFallsBackToLineSyncedThenPlain() {
    const QJsonObject linePayload = makeRecord(1, QStringLiteral("Song"), QStringLiteral("Artist"), 180.0, QString(), LINE_LRC, PLAIN_LYRICS);
    const auto        lineParsed  = vast::LyricsSelector::parsePayload(linePayload, 180.0);

    QVERIFY(lineParsed.has_value());
    QVERIFY(lineParsed->synced);
    QVERIFY(!lineParsed->wordSynced);

    const QJsonObject plainPayload = makeRecord(2, QStringLiteral("Song"), QStringLiteral("Artist"), 180.0, QString(), QString(), PLAIN_LYRICS);
    const auto        plainParsed  = vast::LyricsSelector::parsePayload(plainPayload, 180.0);

    QVERIFY(plainParsed.has_value());
    QVERIFY(!plainParsed->synced);
    QVERIFY(!plainParsed->wordSynced);
    QCOMPARE(plainParsed->lines.size(), 1);
}

void TestLyricsSelector::parsePayloadReturnsNulloptForEmptyRecord() {
    const QJsonObject empty = makeRecord(1, QStringLiteral("Song"), QStringLiteral("Artist"), 180.0, QString(), QString(), QString());
    QVERIFY(!vast::LyricsSelector::parsePayload(empty, 180.0).has_value());
}

void TestLyricsSelector::selectBestCandidatePrefersWordSyncedAmongDuplicateTracks() {
    QJsonArray candidates;
    // Line-synced appears first with exact duration; word-synced appears second within close duration tolerance.
    candidates.append(makeRecord(10, QStringLiteral("Still Alive"), QStringLiteral("Aperture Science"), 176.0, LINE_ONLY_YAML, LINE_LRC, PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Still Alive"), QStringLiteral("Aperture Science"), 177.5, WORD_SYNCED_YAML, LINE_LRC, PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Still Alive"), QStringLiteral("Aperture Science"), 176.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
    QVERIFY(selected->parsed.wordSynced);
}

void TestLyricsSelector::selectBestCandidatePrefersEnhancedLrcOverLineSynced() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), LINE_LRC, PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 201.0, QString(), ENHANCED_LRC, PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
    QVERIFY(selected->parsed.wordSynced);
}

void TestLyricsSelector::selectBestCandidateRejectsFarDurationRemixEvenIfWordSynced() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), LINE_LRC, PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 240.0, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 10);
    QVERIFY(!selected->parsed.wordSynced);
}

void TestLyricsSelector::selectBestCandidatePrefersExactArtistAndTitleOverWordSyncedCover() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Original Artist"), 200.0, QString(), LINE_LRC, PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Cover Band"), 200.0, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Original Artist"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 10);
}

void TestLyricsSelector::selectBestCandidatePrefersSyncedOverPlainWithinMaxDurationDiff() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), QString(), PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 205.0, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
    QVERIFY(selected->parsed.wordSynced);
}

void TestLyricsSelector::selectBestCandidateBreaksTiesByCloserDuration() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 202.5, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 200.2, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
}

void TestLyricsSelector::selectBestCandidateHandlesUnknownRequestedDuration() {
    QJsonArray candidates;
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), LINE_LRC, PLAIN_LYRICS));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 205.0, WORD_SYNCED_YAML, QString(), PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 0.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
    QVERIFY(selected->parsed.wordSynced);
}

void TestLyricsSelector::selectBestCandidateSkipsInstrumentalAndInvalidEntries() {
    QJsonArray candidates;
    candidates.append(QStringLiteral("not an object"));
    candidates.append(makeRecord(10, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), QString(), QString()));
    candidates.append(makeRecord(20, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0, QString(), LINE_LRC, PLAIN_LYRICS));

    const auto selected = vast::LyricsSelector::selectBestCandidate(candidates, QStringLiteral("Track"), QStringLiteral("Singer"), 200.0);

    QVERIFY(selected.has_value());
    QCOMPARE(selected->rawObject.value(QStringLiteral("id")).toInt(), 20);
}

QTEST_GUILESS_MAIN(TestLyricsSelector)
#include "tst_lyricsselector.moc"
