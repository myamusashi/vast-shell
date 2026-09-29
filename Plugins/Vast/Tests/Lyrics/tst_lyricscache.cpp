#include <qbytearray.h>
#include <qdir.h>
#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qregularexpression.h>
#include <qstandardpaths.h>
#include <qstring.h>
#include <qtest.h>

#include "../../Lyrics/LyricsCache.hpp"

namespace {

    [[nodiscard]] QString cacheDir() {
        return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/lyrics");
    }

    // Writes a hand-crafted cache file; save() only emits a well-formed envelope.
    void writeRaw(const QString& cacheKey, const QByteArray& json) {
        QDir{}.mkpath(cacheDir());
        QFile file(cacheDir() + QLatin1Char('/') + cacheKey + QStringLiteral(".json"));
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(json);
        file.close();
    }

    [[nodiscard]] QByteArray base64Of(const QByteArray& raw) {
        return raw.toBase64();
    }

} // namespace

class TestLyricsCache : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void keyIsA40CharacterHexSha1();
    void keyIsStableForTheSameInputs();
    void keyChangesWithTitleArtistOrDuration();
    void theSeparatorPreventsFieldBoundaryCollisions();

    void saveThenLoadRoundTripsRawJsonAndDuration();
    void roundTripsNonAsciiPayloadsByteForByte();
    void loadOnAnUnknownKeyReturnsNullopt();
    void loadRejectsAnEmptyRawPayload();
    void loadRejectsAnOldFormatRawPassthroughFile();
    void loadRejectsATruncatedEnvelope();
    void loadOnAnEnvelopeMissingDurationYieldsZero();
    void saveOverwritesAnExistingEntry();
    void savingTheSamePayloadTwiceIsStable();
    void writesIntoTheCacheLocationLyricsSubdirectory();
};

void TestLyricsCache::initTestCase() {
    // Runs before anything touches CacheLocation, so the real cache is untouched.
    QStandardPaths::setTestModeEnabled(true);
    QDir dir(cacheDir());
    dir.removeRecursively();
}

void TestLyricsCache::keyIsA40CharacterHexSha1() {
    static const QRegularExpression hex(QStringLiteral("^[0-9a-f]{40}$"));
    QVERIFY(hex.match(vast::LyricsCache::key(QStringLiteral("t"), QStringLiteral("a"), 1.0)).hasMatch());
}

void TestLyricsCache::keyIsStableForTheSameInputs() {
    QCOMPARE(vast::LyricsCache::key(QStringLiteral("Title"), QStringLiteral("Artist"), 213.5), vast::LyricsCache::key(QStringLiteral("Title"), QStringLiteral("Artist"), 213.5));
}

void TestLyricsCache::keyChangesWithTitleArtistOrDuration() {
    const QString base = vast::LyricsCache::key(QStringLiteral("Title"), QStringLiteral("Artist"), 213.5);

    QVERIFY(base != vast::LyricsCache::key(QStringLiteral("Other"), QStringLiteral("Artist"), 213.5));
    QVERIFY(base != vast::LyricsCache::key(QStringLiteral("Title"), QStringLiteral("Other"), 213.5));
    QVERIFY(base != vast::LyricsCache::key(QStringLiteral("Title"), QStringLiteral("Artist"), 214.5));
}

void TestLyricsCache::theSeparatorPreventsFieldBoundaryCollisions() {
    // The "|" separator keeps these two preimages distinct.
    QVERIFY(vast::LyricsCache::key(QStringLiteral("a|b"), QStringLiteral("c"), 1.0) != vast::LyricsCache::key(QStringLiteral("a"), QStringLiteral("b|c"), 1.0));
}

void TestLyricsCache::saveThenLoadRoundTripsRawJsonAndDuration() {
    const QString    key     = QStringLiteral("tst-roundtrip");
    const QByteArray payload = R"({"code":200,"syncedLyrics":"[00:01.00]hi","duration":213.5})";

    vast::LyricsCache::save(key, payload, 213.5);
    const auto loaded = vast::LyricsCache::load(key);

    QVERIFY(loaded.has_value());
    QCOMPARE(loaded->rawJson, payload);
    QCOMPARE(loaded->durationSecs, 213.5);
}

void TestLyricsCache::roundTripsNonAsciiPayloadsByteForByte() {
    const QString key = QStringLiteral("tst-utf8");
    // Accents, CJK and a non-BMP emoji, so the base64 envelope is proven lossless.
    const QByteArray payload = QString::fromUtf8("{\"t\":\"Café 日本語 🎵\"}").toUtf8();

    vast::LyricsCache::save(key, payload, 1.0);
    const auto loaded = vast::LyricsCache::load(key);

    QVERIFY(loaded.has_value());
    QCOMPARE(loaded->rawJson, payload);
}

void TestLyricsCache::loadOnAnUnknownKeyReturnsNullopt() {
    QVERIFY(!vast::LyricsCache::load(QStringLiteral("tst-never-written")).has_value());
}

void TestLyricsCache::loadRejectsAnEmptyRawPayload() {
    const QString key = QStringLiteral("tst-empty-raw");
    vast::LyricsCache::save(key, QByteArray(), 100.0);

    // A decoded-empty raw is a miss, not an empty hit.
    QVERIFY(!vast::LyricsCache::load(key).has_value());
}

void TestLyricsCache::loadRejectsAnOldFormatRawPassthroughFile() {
    const QString key = QStringLiteral("tst-oldformat");
    // The pre-envelope format stored the payload verbatim; such files miss on purpose.
    writeRaw(key, R"([{"id":1,"trackName":"x"}])");

    QVERIFY(!vast::LyricsCache::load(key).has_value());
}

void TestLyricsCache::loadRejectsATruncatedEnvelope() {
    const QString key = QStringLiteral("tst-truncated");
    writeRaw(key, QByteArrayLiteral("{\"raw\":"));

    QVERIFY(!vast::LyricsCache::load(key).has_value());
}

void TestLyricsCache::loadOnAnEnvelopeMissingDurationYieldsZero() {
    const QString    key     = QStringLiteral("tst-noduration");
    const QByteArray payload = R"({"code":200})";
    writeRaw(key, R"({"raw":")" + base64Of(payload) + R"("})");

    // The load succeeds and the duration falls back to 0.
    const auto loaded = vast::LyricsCache::load(key);
    QVERIFY(loaded.has_value());
    QCOMPARE(loaded->rawJson, payload);
    QCOMPARE(loaded->durationSecs, 0.0);
}

void TestLyricsCache::saveOverwritesAnExistingEntry() {
    const QString key = QStringLiteral("tst-overwrite");
    vast::LyricsCache::save(key, QByteArrayLiteral("{\"v\":1}"), 10.0);
    vast::LyricsCache::save(key, QByteArrayLiteral("{\"v\":2}"), 20.0);

    const auto loaded = vast::LyricsCache::load(key);
    QVERIFY(loaded.has_value());
    QCOMPARE(loaded->rawJson, QByteArrayLiteral("{\"v\":2}"));
    QCOMPARE(loaded->durationSecs, 20.0);
}

void TestLyricsCache::savingTheSamePayloadTwiceIsStable() {
    const QString    key     = QStringLiteral("tst-idempotent");
    const QByteArray payload = R"({"code":200,"plainLyrics":"line"})";

    vast::LyricsCache::save(key, payload, 99.0);
    const auto first = vast::LyricsCache::load(key);
    vast::LyricsCache::save(key, payload, 99.0);
    const auto second = vast::LyricsCache::load(key);

    QVERIFY(first.has_value());
    QVERIFY(second.has_value());
    QCOMPARE(second->rawJson, first->rawJson);
    QCOMPARE(second->durationSecs, first->durationSecs);
}

void TestLyricsCache::writesIntoTheCacheLocationLyricsSubdirectory() {
    // path() is private, so the location is checked by its effect.
    vast::LyricsCache::save(QStringLiteral("tst-location"), QByteArrayLiteral("{}"), 1.0);

    QVERIFY2(QDir(cacheDir()).exists(), qPrintable(cacheDir()));
}

QTEST_GUILESS_MAIN(TestLyricsCache)
#include "tst_lyricscache.moc"
