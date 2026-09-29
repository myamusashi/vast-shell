#include <qbytearray.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>

#include "../../FuzzyCore.hpp"
#include "../../FuzzyMatcher.hpp"

#include <array>

// Ranking vectors ported from the vendored upstream fzy suite
// (Plugins/third_party/fzy/test/test_match.c), which is the authority on what
// fzy scoring should prefer.
namespace {

    double rank(const char* needle, const char* haystack) {
        return vast::fzy::score(QString::fromLatin1(needle), QString::fromLatin1(haystack));
    }

} // namespace

class TestFuzzy : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    // --- upstream fzy parity: has_match ---
    void exactMatchIsTrue();
    void partialMatchIsTrue();
    void delimitersBetweenNeedleCharsStillMatch();
    void nonMatchIsFalse();
    void emptyNeedleNeverMatches();

    // --- upstream fzy parity: ranking ---
    void prefersWordStarts();
    void prefersConsecutiveLetters();
    void prefersContiguousOverPeriodBoundary();
    void prefersShorterMatches();
    void prefersShorterCandidates();
    void prefersStartOfCandidate();
    void prefersShorterPathsOnTie();

    // --- upstream fzy parity: positions ---
    void positionsConsecutive();
    void positionsPreferWordStart();
    void positionsWithoutBonuses();
    void positionsMultipleCandidatesPickWordStarts();
    void positionsExactMatch();

    // --- FuzzyCore contract beyond upstream ---
    void scoredMatchAgreesWithGateAndScore();
    void utf8OverloadAgreesWithQStringOverload();
    void positionsAreStrictlyAscendingAndInRange();
    void positionsAreQCharIndicesNotByteOffsets();
    void overlongHaystackIsUnscoreable();
    void needleLongerThanHaystackDoesNotMatch();
    void scoresAreFinite();

    // --- FuzzyMatcher: normalization ---
    void normalizesAccentedLatin();
    void normalizationIsIdempotent();
    void iAndLShareAFoldTarget();
    void normalizationFoldsLeetspeak();
    void normalizationLowercasesAscii();
    void normalizationPreservesLength();

    // --- FuzzyMatcher: html escaping ---
    void escapesAllFiveEntities();
    void escapeIsIdentityOnPlainText();

    // --- FuzzyMatcher: highlighting ---
    void highlightWrapsMatchedRun();
    void highlightEscapesInsideAndOutside();
    void highlightWithoutMatchIsPlainEscaped();
    void highlightEmptyQueryIsPlainEscaped();

    // --- FuzzyMatcher: scoring ---
    void emptyQueryScoresZero();
    void whitespaceOnlyQueryScoresZero();
    void exactMatchOutranksPartial();
    void multiWordAveragesAcrossWords();
    void typoFallbackFindsNonSubsequence();
    void cachedEncodingMatchesStringApi();
    void multiFieldPrefersPrimaryWhenDecisive();
    void secondaryFieldOnlyCountsWhenPrimaryFails();
};

void TestFuzzy::exactMatchIsTrue() {
    QVERIFY(vast::fzy::hasMatch(QStringLiteral("a"), QStringLiteral("a")));
}

void TestFuzzy::partialMatchIsTrue() {
    QVERIFY(vast::fzy::hasMatch(QStringLiteral("a"), QStringLiteral("ab")));
    QVERIFY(vast::fzy::hasMatch(QStringLiteral("a"), QStringLiteral("ba")));
}

void TestFuzzy::delimitersBetweenNeedleCharsStillMatch() {
    QVERIFY(vast::fzy::hasMatch(QStringLiteral("abc"), QStringLiteral("a|b|c")));
}

void TestFuzzy::nonMatchIsFalse() {
    QVERIFY(!vast::fzy::hasMatch(QStringLiteral("a"), QString()));
    QVERIFY(!vast::fzy::hasMatch(QStringLiteral("a"), QStringLiteral("b")));
    QVERIFY(!vast::fzy::hasMatch(QStringLiteral("ass"), QStringLiteral("tags")));
}

// Deviation from upstream, which matches an empty needle. An empty needle
// means "no filter" here, so it must not count as a match.
void TestFuzzy::emptyNeedleNeverMatches() {
    QVERIFY(!vast::fzy::hasMatch(QString(), QString()));
    QVERIFY(!vast::fzy::hasMatch(QString(), QStringLiteral("a")));
    QVERIFY(!vast::fzy::scoredMatch(QString(), QStringLiteral("a")).matched);
}

void TestFuzzy::prefersWordStarts() {
    QVERIFY2(rank("amor", "app/models/order") > rank("amor", "app/models/zrder"), "a match starting a word must outrank one in the middle of one");
}

void TestFuzzy::prefersConsecutiveLetters() {
    QVERIFY2(rank("amo", "app/m/foo") < rank("amo", "app/models/foo"), "scattered letters must rank below consecutive ones");
}

void TestFuzzy::prefersContiguousOverPeriodBoundary() {
    QVERIFY2(rank("gemfil", "Gemfile.lock") < rank("gemfil", "Gemfile"), "a contiguous run must outrank the same letters split by a period");
}

void TestFuzzy::prefersShorterMatches() {
    QVERIFY(rank("abce", "abcdef") > rank("abce", "abc de"));
    QVERIFY(rank("abc", "    a b c ") > rank("abc", " a  b  c "));
    QVERIFY(rank("abc", " a b c    ") > rank("abc", " a  b  c "));
}

void TestFuzzy::prefersShorterCandidates() {
    QVERIFY2(rank("test", "tests") > rank("test", "testing"), "a shorter candidate sharing the prefix must win");
}

void TestFuzzy::prefersStartOfCandidate() {
    QVERIFY(rank("test", "testing") > rank("test", "/testing"));
}

void TestFuzzy::prefersShorterPathsOnTie() {
    // A deeper path must score lower.
    QVERIFY2(rank("src", "src/main.cpp") > rank("src", "a/b/src/main.cpp"), "a match near the start of the path must outrank a buried one");
}

void TestFuzzy::positionsConsecutive() {
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("amo"), QStringLiteral("app/models/foo"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{0, 4, 5}));
}

void TestFuzzy::positionsPreferWordStart() {
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("amor"), QStringLiteral("app/models/order"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{0, 4, 11, 12}));
}

void TestFuzzy::positionsWithoutBonuses() {
    vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("as"), QStringLiteral("tags"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{1, 3}));

    result = vast::fzy::matchPositions(QStringLiteral("as"), QStringLiteral("examples.txt"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{2, 7}));
}

void TestFuzzy::positionsMultipleCandidatesPickWordStarts() {
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("abc"), QStringLiteral("a/a/b/c/c"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{2, 4, 6}));
}

void TestFuzzy::positionsExactMatch() {
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("foo"), QStringLiteral("foo"));
    QVERIFY(result.matched);
    QCOMPARE(result.positions, (std::vector<int>{0, 1, 2}));
}

// The combined API must agree with hasMatch() + score().
void TestFuzzy::scoredMatchAgreesWithGateAndScore() {
    const std::array cases = {
        std::pair{QStringLiteral("app"), QStringLiteral("app/models/order")},
        std::pair{QStringLiteral("amor"), QStringLiteral("app/models/order")},
        std::pair{QStringLiteral("zzz"), QStringLiteral("app/models/order")},
        std::pair{QStringLiteral("a"), QStringLiteral("a")},
        std::pair{QString(), QStringLiteral("abc")},
    };

    for (const auto& [needle, haystack] : cases) {
        const bool                    gated   = vast::fzy::hasMatch(needle, haystack);
        const vast::fzy::ScoreOutcome outcome = vast::fzy::scoredMatch(needle, haystack);
        QCOMPARE(outcome.matched, gated);
        if (gated)
            QCOMPARE(outcome.score, vast::fzy::score(needle, haystack));
        else
            QCOMPARE(outcome.score, 0.0);
    }
}

void TestFuzzy::utf8OverloadAgreesWithQStringOverload() {
    const std::array cases = {
        std::pair{QStringLiteral("app"), QStringLiteral("app/models/order")},
        std::pair{QStringLiteral("café"), QStringLiteral("le café noir")},
        std::pair{QStringLiteral("日本"), QStringLiteral("日本語ファイル")},
        std::pair{QStringLiteral("zzz"), QStringLiteral("app")},
    };

    for (const auto& [needle, haystack] : cases) {
        const QByteArray              needleUtf8   = needle.toUtf8();
        const QByteArray              haystackUtf8 = haystack.toUtf8();
        const qsizetype               charCount    = needle.length();

        const vast::fzy::ScoreOutcome viaQString = vast::fzy::scoredMatch(needle, haystack);
        const vast::fzy::ScoreOutcome viaUtf8    = vast::fzy::scoredMatchUtf8(needleUtf8, charCount, haystackUtf8);
        QCOMPARE(viaUtf8.matched, viaQString.matched);
        QCOMPARE(viaUtf8.score, viaQString.score);

        const vast::fzy::MatchResult posQString = vast::fzy::matchPositions(needle, haystack);
        const vast::fzy::MatchResult posUtf8    = vast::fzy::matchPositionsUtf8(needleUtf8, charCount, haystackUtf8);
        QCOMPARE(posUtf8.matched, posQString.matched);
        QCOMPARE(posUtf8.positions, posQString.positions);
    }
}

void TestFuzzy::positionsAreStrictlyAscendingAndInRange() {
    const QStringList needles{QStringLiteral("a"), QStringLiteral("src"), QStringLiteral("cpp"), QStringLiteral("日本語")};
    const QStringList haystacks{QStringLiteral("src/main.cpp"), QStringLiteral("a"), QStringLiteral("日本語ファイル.txt"),
                                QStringLiteral("a very long path with many separators/and/many/segments/inside/it.cpp")};

    for (const QString& needle : needles) {
        for (const QString& haystack : haystacks) {
            const vast::fzy::MatchResult result = vast::fzy::matchPositions(needle, haystack);
            if (!result.matched) {
                QVERIFY(result.positions.empty());
                continue;
            }
            QCOMPARE(result.positions.size(), needle.size());
            for (size_t i = 0; i < result.positions.size(); ++i) {
                const int position = result.positions.at(i);
                QVERIFY2(position >= 0 && position < haystack.size(), qPrintable(QStringLiteral("position %1 out of range for %2").arg(position).arg(haystack)));
                if (i > 0)
                    QVERIFY2(position > result.positions.at(i - 1), "positions must be strictly ascending");
                // Each position must carry the matched character.
                QCOMPARE(haystack.at(position).toLower(), needle.at(static_cast<qsizetype>(i)).toLower());
            }
        }
    }
}

// Positions are QChar indices, not the byte offsets fzy reports.
void TestFuzzy::positionsAreQCharIndicesNotByteOffsets() {
    const QString                haystack = QStringLiteral("日本語ファイル");
    const QString                needle   = QStringLiteral("ファイル");
    const vast::fzy::MatchResult result   = vast::fzy::matchPositions(needle, haystack);
    QVERIFY(result.matched);

    QCOMPARE(result.positions.size(), needle.size());
    for (size_t i = 0; i < result.positions.size(); ++i) {
        const qsizetype position = result.positions.at(i);
        QCOMPARE(haystack.at(position), needle.at(static_cast<qsizetype>(i)));
    }
    // Byte offsets would have run past the string.
    QVERIFY(result.positions.back() < haystack.size());
}

void TestFuzzy::overlongHaystackIsUnscoreable() {
    const QString                huge(3000, QChar('a'));
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("a"), huge);
    // Gated as a match, but not scoreable: no backtrace.
    QVERIFY(!result.matched);
    QVERIFY(result.positions.empty());
}

void TestFuzzy::needleLongerThanHaystackDoesNotMatch() {
    const vast::fzy::MatchResult result = vast::fzy::matchPositions(QStringLiteral("abcdef"), QStringLiteral("abc"));
    QVERIFY(!result.matched);
    QVERIFY(result.positions.empty());
}

// fzy signals "no score" with infinity; the port substitutes finite sentinels.
void TestFuzzy::scoresAreFinite() {
    const std::array cases = {
        std::pair{QStringLiteral("app"), QStringLiteral("app")},
        std::pair{QStringLiteral("app"), QStringLiteral("application/models/order")},
        std::pair{QStringLiteral("a"), QString(3000, QChar('a'))},
    };

    for (const auto& [needle, haystack] : cases) {
        const vast::fzy::ScoreOutcome outcome = vast::fzy::scoredMatch(needle, haystack);
        QVERIFY2(std::isfinite(outcome.score), "score must be finite so callers can blend arithmetically");
        const vast::fzy::MatchResult result = vast::fzy::matchPositions(needle, haystack);
        QVERIFY(std::isfinite(result.score));
    }
}

void TestFuzzy::normalizesAccentedLatin() {
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("Café")), QStringLiteral("cafe"));
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("naïve")), QStringLiteral("naive"));
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("ÄÖÜ")), QStringLiteral("aou"));
    // Ł is not in the fold table, so it passes through unchanged.
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("Łódź")), QStringLiteral("łodz"));
}

void TestFuzzy::normalizationIsIdempotent() {
    // Not idempotent: the 'i'/'l' fold-table collision (see
    // iAndLShareAFoldTarget) turns "naive" into "nalve" on a second pass.
    const QString once  = vast::FuzzyMatcher::normalizeText(QStringLiteral("naïve"));
    const QString twice = vast::FuzzyMatcher::normalizeText(once);
    QCOMPARE(once, QStringLiteral("naive"));
    QCOMPARE(twice, QStringLiteral("nalve"));
}

// Typing "i" searches for "l": the 'i' and 'l' fold-table rows both claim
// '1', '!', '|' and each other, and 'l' is inserted last.
void TestFuzzy::iAndLShareAFoldTarget() {
    for (const QChar c : {QChar('i'), QChar('I'), QChar('1'), QChar('!'), QChar('|')})
        QCOMPARE(vast::FuzzyMatcher::normalizeChar(c), QChar('l'));
    QCOMPARE(vast::FuzzyMatcher::normalizeChar(QChar('l')), QChar('l'));
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("firefox")), QStringLiteral("flrefox"));
}

void TestFuzzy::normalizationFoldsLeetspeak() {
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("h4ck")), QStringLiteral("hack"));
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("g0sh")), QStringLiteral("gosh"));
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("l33t")), QStringLiteral("leet"));
}

void TestFuzzy::normalizationLowercasesAscii() {
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("ABCdef")), QStringLiteral("abcdef"));
    // Digits and punctuation are folded too; see normalizationFoldsLeetspeak.
    QCOMPARE(vast::FuzzyMatcher::normalizeText(QStringLiteral("MiXeD App")), QStringLiteral("mlxed app"));
}

void TestFuzzy::normalizationPreservesLength() {
    // highlightedHtml slices the original using positions from the normalized
    // text, so normalization must preserve length.
    const QStringList samples{QStringLiteral("Café"), QStringLiteral("日本語"), QStringLiteral("naïve"), QStringLiteral("Ångström"), QStringLiteral("İ"), QStringLiteral("açaí")};
    for (const QString& sample : samples)
        QCOMPARE(vast::FuzzyMatcher::normalizeText(sample).length(), sample.length());
}

void TestFuzzy::escapesAllFiveEntities() {
    QCOMPARE(vast::FuzzyMatcher::escapeHtml(QStringLiteral("<&>\"'")), QStringLiteral("&lt;&amp;&gt;&quot;&#039;"));
}

void TestFuzzy::escapeIsIdentityOnPlainText() {
    const QString plain = QStringLiteral("Firefox web browser");
    QCOMPARE(vast::FuzzyMatcher::escapeHtml(plain), plain);
}

void TestFuzzy::highlightWrapsMatchedRun() {
    const QString html = vast::FuzzyMatcher::highlightedHtml(QStringLiteral("Firefox"), QStringLiteral("fox"), QStringLiteral("red"));
    // The run is the lowercase tail: "Firefox" has no capital-F "Fox".
    QCOMPARE(html, QStringLiteral("Fire<span style=\"color:red;font-weight:600;\">fox</span>"));
}

void TestFuzzy::highlightEscapesInsideAndOutside() {
    // An app name must never emit raw HTML, inside or outside the run.
    const QString html = vast::FuzzyMatcher::highlightedHtml(QStringLiteral("<b>Bold</b>"), QStringLiteral("bold"), QStringLiteral("red"));
    QVERIFY(!html.contains(QLatin1String("<b>")));
    QVERIFY(html.contains(QLatin1String("&lt;b&gt;")));

    const QString matched = vast::FuzzyMatcher::highlightedHtml(QStringLiteral("a<b"), QStringLiteral("ab"), QStringLiteral("red"));
    QVERIFY(!matched.contains(QLatin1String("a<b\" style")));
    QVERIFY(matched.contains(QLatin1String("&lt;")));
}

void TestFuzzy::highlightWithoutMatchIsPlainEscaped() {
    const QString html = vast::FuzzyMatcher::highlightedHtml(QStringLiteral("Firefox"), QStringLiteral("zzz"), QStringLiteral("red"));
    QCOMPARE(html, QStringLiteral("Firefox"));
    QVERIFY(!html.contains(QLatin1String("<span")));
}

void TestFuzzy::highlightEmptyQueryIsPlainEscaped() {
    QCOMPARE(vast::FuzzyMatcher::highlightedHtml(QStringLiteral("a<b"), QString(), QStringLiteral("red")), QStringLiteral("a&lt;b"));
    QCOMPARE(vast::FuzzyMatcher::highlightedHtml(QStringLiteral("a<b"), QStringLiteral("   "), QStringLiteral("red")), QStringLiteral("a&lt;b"));
}

void TestFuzzy::emptyQueryScoresZero() {
    QCOMPARE(vast::FuzzyMatcher::fuzzyScore(QString(), QStringLiteral("Firefox")), 0.0);
    QCOMPARE(vast::FuzzyMatcher::fuzzyScore(QString(), QString()), 0.0);
}

void TestFuzzy::whitespaceOnlyQueryScoresZero() {
    QCOMPARE(vast::FuzzyMatcher::fuzzyScore(QStringLiteral("   "), QStringLiteral("Firefox")), 0.0);
    QCOMPARE(vast::FuzzyMatcher::fuzzyScore(QStringLiteral("\t\n"), QStringLiteral("Firefox")), 0.0);
}

void TestFuzzy::exactMatchOutranksPartial() {
    const double exact    = vast::FuzzyMatcher::fuzzyScore(QStringLiteral("firefox"), QStringLiteral("firefox"));
    const double embedded = vast::FuzzyMatcher::fuzzyScore(QStringLiteral("firefox"), QStringLiteral("mozilla firefox nightly"));
    QVERIFY2(exact > embedded, "an exact match must outrank the same text embedded in a longer string");
}

void TestFuzzy::multiWordAveragesAcrossWords() {
    // Words are averaged, so matching a subset must score below matching all.
    const double both = vast::FuzzyMatcher::fuzzyScore(QStringLiteral("fire fox"), QStringLiteral("firefox"));
    const double one  = vast::FuzzyMatcher::fuzzyScore(QStringLiteral("fire xyz"), QStringLiteral("firefox"));
    QVERIFY2(both > one, "matching every query word must outrank matching a subset");
}

void TestFuzzy::typoFallbackFindsNonSubsequence() {
    // Not a subsequence, so only the edit-distance fallback can find it.
    QVERIFY(!vast::fzy::hasMatch(QStringLiteral("firefoz"), QStringLiteral("firefox")));
    const double typo = vast::FuzzyMatcher::fuzzyScore(QStringLiteral("firefoz"), QStringLiteral("firefox"));
    QVERIFY2(typo > 0.0, "the typo fallback must still produce a positive score");
}

void TestFuzzy::cachedEncodingMatchesStringApi() {
    // The Utf8 variants are an optimization and must match the QString API.
    const QStringList queries{QStringLiteral("fire"), QStringLiteral("fire fox"), QStringLiteral("café"), QStringLiteral("日本")};
    const QStringList fields{QStringLiteral("firefox"), QStringLiteral("mozilla firefox"), QStringLiteral("le café"), QStringLiteral("日本語ファイル"), QStringLiteral("")};

    for (const QString& query : queries) {
        for (const QString& field : fields) {
            const QStringList words      = vast::FuzzyMatcher::normalizeText(query).split(QLatin1Char(' '), Qt::SkipEmptyParts);
            const double      viaStrings = vast::FuzzyMatcher::multiWordScore(words, vast::FuzzyMatcher::normalizeText(field));
            const double      viaCached =
                vast::FuzzyMatcher::multiWordScoreUtf8(vast::FuzzyMatcher::encodeWords(words), vast::FuzzyMatcher::cacheText(vast::FuzzyMatcher::normalizeText(field)));
            QCOMPARE(viaCached, viaStrings);
        }
    }
}

void TestFuzzy::multiFieldPrefersPrimaryWhenDecisive() {
    // A perfect primary match short-circuits, so the result equals it.
    const QStringList words{QStringLiteral("firefox")};
    const double      primary     = vast::FuzzyMatcher::multiFieldScore(words, QStringLiteral("firefox"), QStringLiteral("firefox"), QStringLiteral("zzzz"));
    const double      primaryOnly = vast::FuzzyMatcher::multiWordScore(words, QStringLiteral("firefox"));
    QCOMPARE(primary, primaryOnly);
}

void TestFuzzy::secondaryFieldOnlyCountsWhenPrimaryFails() {
    // A secondary hit must still score, below the same text in the primary.
    const QStringList words{QStringLiteral("editor")};
    const double      viaSecondary = vast::FuzzyMatcher::multiFieldScore(words, QStringLiteral("editor"), QStringLiteral("zzzzzz"), QStringLiteral("text editor"), QString());
    const double      viaPrimary   = vast::FuzzyMatcher::multiFieldScore(words, QStringLiteral("editor"), QStringLiteral("text editor"), QString());
    QVERIFY2(viaSecondary > 0.0, "a secondary-field match must contribute");
    QVERIFY2(viaPrimary > viaSecondary, "the same text must score higher in the primary field than the secondary");
}

QTEST_MAIN(TestFuzzy)
#include "tst_fuzzy.moc"
