#pragma once

#include <QChar>
#include <QHash>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

// ---------------------------------------------------------------------------
// FuzzyMatcher — pure static scoring engine.
// All methods are stateless; safe to call from any thread.
// ---------------------------------------------------------------------------
class FuzzyMatcher {
  public:
    // ── Weights ──────────────────────────────────────────────────────────────
    static constexpr double kPrefixWeight       = 0.30;
    static constexpr double kDistanceWeight     = 0.20;
    static constexpr double kConsecutiveWeight  = 0.15;
    static constexpr double kWordBoundaryWeight = 0.10;
    static constexpr double kAcronymWeight      = 0.25;
    static constexpr double kRecencyWeight      = 0.40;

    // ── Normalisation ─────────────────────────────────────────────────────────
    static QChar   normalizeChar(QChar c);
    static QString normalizeText(const QString& text);

    // ── Highlight helpers ─────────────────────────────────────────────────────
    // [{start, length}, …] covering every match of query inside text.
    static QVariantList highlightRanges(const QString& text, const QString& query);

    // HTML string with matching spans coloured.
    static QString highlightedHtml(const QString& text, const QString& query, const QString& color);

    static QString escapeHtml(const QString& text);

    // ── Scoring ───────────────────────────────────────────────────────────────
    static double getScore(const QString& q, const QString& t, const QStringList& tWords);

    static double getMultiWordScore(const QStringList& qWords, const QString& t, const QStringList& tWords);

    // Top-level: normalise + split + score. Returns [0, 1].
    static double fuzzyScore(const QString& query, const QString& text);

  private:
    static bool                       isSubsequence(const QString& q, const QString& t);
    static double                     subsequenceScore(const QString& q, const QString& t);
    static int                        levenshteinDistance(const QString& a, const QString& b);
    static double                     distanceScore(const QString& a, const QString& b);
    static double                     prefixScore(const QString& q, const QString& t, const QStringList& tWords);
    static double                     wordBoundaryScore(const QString& q, const QStringList& tWords);
    static double                     acronymScore(const QString& q, const QStringList& tWords);

    static const QHash<QChar, QChar>& charLookup();
};
