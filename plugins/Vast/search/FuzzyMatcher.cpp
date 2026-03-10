#include "FuzzyMatcher.hpp"

#include <QRegularExpression>
#include <algorithm>
#include <cmath>
#include <qtypes.h>

// char normalisation table
const QHash<QChar, QChar>& FuzzyMatcher::charLookup() {
    static QHash<QChar, QChar> map = []() {
        // raw map: canonical → lookalike string
        const struct {
            char        key;
            const char* chars;
        } entries[] = {
            {'a', "aàáâãäåāăą4@"}, {'e', "eèéêëēėę3"}, {'i', "iìíîïīįı1!|l"}, {'o', "oòóôõöøōő0"}, {'u', "uùúûüūůű"}, {'c', "cçćč"},
            {'n', "nñńň"},         {'s', "sśšş5$"},    {'z', "zźżž2"},        {'l', "l1!|i"},      {'g', "g9"},       {'t', "t7+"},
        };
        QHash<QChar, QChar> h;
        for (auto& e : entries) {
            const QString chars = QString::fromUtf8(e.chars);
            const QChar   canon(e.key);
            for (QChar c : chars)
                h.insert(c, canon);
        }
        return h;
    }();
    return map;
}

QChar FuzzyMatcher::normalizeChar(QChar c) {
    const QChar lower = c.toLower();
    return charLookup().value(lower, lower);
}

QString FuzzyMatcher::normalizeText(const QString& text) {
    QString out;
    out.reserve(text.size());
    for (QChar c : text)
        out += normalizeChar(c);
    return out;
}

// HTML helpers
QString FuzzyMatcher::escapeHtml(const QString& text) {
    QString out = text;
    out.replace('&', "&amp;");
    out.replace('<', "&lt;");
    out.replace('>', "&gt;");
    out.replace('"', "&quot;");
    out.replace('\'', "&#039;");
    return out;
}

// Returns [{start, length}, …] covering every match of query inside text.
QVariantList FuzzyMatcher::highlightRanges(const QString& text, const QString& query) {
    QVariantList ranges;
    if (query.trimmed().isEmpty())
        return ranges;

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return ranges;

    const QString normText = normalizeText(text);

    qsizetype     pos = 0;
    while ((pos = normText.indexOf(normQuery, pos)) != -1) {
        QVariantMap range;
        range["start"]  = pos;
        range["length"] = normQuery.length();
        ranges.append(range);
        pos += normQuery.length();
    }
    return ranges;
}

QString FuzzyMatcher::highlightedHtml(const QString& text, const QString& query, const QString& color) {
    if (query.trimmed().isEmpty())
        return escapeHtml(text);

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return escapeHtml(text);

    const QString normText = normalizeText(text);

    QString       result;
    qsizetype     last = 0;
    qsizetype     idx  = normText.indexOf(normQuery);

    while (idx != -1) {
        if (idx > last)
            result += escapeHtml(text.mid(last, idx - last));

        result += QStringLiteral("<span style=\"color:%1;font-weight:600;\">").arg(color);
        result += escapeHtml(text.mid(idx, normQuery.length()));
        result += QStringLiteral("</span>");

        last = idx + normQuery.length();
        idx  = normText.indexOf(normQuery, last);
    }

    if (last < text.length())
        result += escapeHtml(text.mid(last));

    return result;
}

bool FuzzyMatcher::isSubsequence(const QString& q, const QString& t) {
    int qi = 0;
    for (int i = 0; i < t.length() && qi < q.length(); ++i)
        if (t[i] == q[qi])
            ++qi;
    return qi == q.length();
}

double FuzzyMatcher::subsequenceScore(const QString& q, const QString& t) {
    if (q.isEmpty())
        return 1.0;

    int    qi = 0, consecutive = 0;
    double bonus = 0.0;

    for (int i = 0; i < t.length() && qi < q.length(); ++i) {
        if (t[i] == q[qi]) {
            ++consecutive;
            bonus += consecutive * (i == 0 || t[i - 1] == ' ' ? 2.0 : 1.0);
            ++qi;
        } else {
            consecutive = 0;
        }
    }
    if (qi < q.length())
        return 0.0;

    const double maxBonus = static_cast<double>(q.length() * (q.length() + 1));
    return std::min(bonus / maxBonus, 1.0);
}

qsizetype FuzzyMatcher::levenshteinDistance(const QString& a, const QString& b) {
    if (a.isEmpty())
        return b.length();
    if (b.isEmpty())
        return a.length();

    const QString&         shorter = a.length() <= b.length() ? a : b;
    const QString&         longer  = a.length() <= b.length() ? b : a;

    const qsizetype        slen = shorter.length();
    const qsizetype        llen = longer.length();

    std::vector<qsizetype> prev(slen + 1), curr(slen + 1);
    for (qsizetype i = 0; i <= slen; ++i)
        prev[i] = i;

    for (qsizetype i = 1; i <= llen; ++i) {
        curr[0]          = i;
        qsizetype rowMin = curr[0];

        for (qsizetype j = 1; j <= slen; ++j) {
            const qsizetype cost = (longer[i - 1] == shorter[j - 1]) ? 0 : 1;
            curr[j]              = std::min({prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost});
            rowMin               = std::min(rowMin, curr[j]);
        }

        if (rowMin > slen)
            return rowMin;

        std::swap(prev, curr);
    }
    return prev[slen];
}

double FuzzyMatcher::distanceScore(const QString& a, const QString& b) {
    const int maxLen = static_cast<int>(std::max(a.length(), b.length()));
    if (maxLen == 0)
        return 1.0;

    // Skip Levenshtein when the length gap makes a good match impossible.
    const int lenDiff = static_cast<int>(std::abs(a.length() - b.length()));
    if (static_cast<double>(lenDiff) / maxLen > 0.7)
        return 0.0;

    const qsizetype dist  = levenshteinDistance(a, b);
    const double    ratio = static_cast<double>(maxLen - dist) / maxLen;
    return std::pow(ratio, 1.5);
}

double FuzzyMatcher::prefixScore(const QString& q, const QString& t, const QStringList& tWords) {
    if (t.startsWith(q))
        return (q.length() == t.length()) ? 1.0 : 0.95;

    for (const QString& word : tWords)
        if (word.startsWith(q))
            return (q.length() == word.length()) ? 0.9 : 0.85;

    return 0.0;
}

double FuzzyMatcher::wordBoundaryScore(const QString& q, const QStringList& tWords) {
    double best = 0.0;
    for (const QString& word : tWords)
        if (word.contains(q))
            best = std::max(best, static_cast<double>(q.length()) / word.length());
    return best;
}

double FuzzyMatcher::acronymScore(const QString& q, const QStringList& tWords) {
    if (tWords.size() < 2 || q.isEmpty())
        return 0.0;

    QString acronym;
    for (const QString& w : tWords)
        if (!w.isEmpty())
            acronym += w[0];

    if (acronym == q)
        return 1.0;
    if (acronym.startsWith(q))
        return 0.9;
    if (acronym.contains(q))
        return 0.75;
    if (isSubsequence(q, acronym))
        return 0.6;
    return 0.0;
}

double FuzzyMatcher::getScore(const QString& q, const QString& t, const QStringList& tWords) {
    if (t == q)
        return 1.0;
    if (t.contains(q))
        return 0.95;

    // Acronym path ("vsc" → "Visual Studio Code")
    const double acro = acronymScore(q, tWords);
    if (acro > 0.0)
        return acro * kAcronymWeight + prefixScore(q, t, tWords) * kPrefixWeight + wordBoundaryScore(q, tWords) * kWordBoundaryWeight;

    const double lenRatio = static_cast<double>(std::min(q.length(), t.length())) / static_cast<double>(std::max(q.length(), t.length()));
    if (lenRatio < 0.3 && !isSubsequence(q, t))
        return 0.0;

    return distanceScore(q, t) * kDistanceWeight + prefixScore(q, t, tWords) * kPrefixWeight + subsequenceScore(q, t) * kConsecutiveWeight +
        wordBoundaryScore(q, tWords) * kWordBoundaryWeight;
}

double FuzzyMatcher::getMultiWordScore(const QStringList& qWords, const QString& t, const QStringList& tWords) {
    if (qWords.size() == 1)
        return getScore(qWords[0], t, tWords);

    double    total   = 0.0;
    qsizetype matched = 0;

    for (const QString& qw : qWords) {
        const double s = getScore(qw, t, tWords);
        if (s > 0.0) {
            total += s;
            ++matched;
        }
    }
    // All query words must contribute.
    if (matched < qWords.size())
        return 0.0;

    return total / static_cast<double>(qWords.size());
}

double FuzzyMatcher::fuzzyScore(const QString& query, const QString& text) {
    if (query.isEmpty())
        return 0.0;

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return 0.0;

    const QString normText = normalizeText(text);
    if (normText == normQuery)
        return 1.0;
    if (normText.contains(normQuery))
        return 0.95;

    const QStringList tWords     = normText.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
    const QStringList queryWords = normQuery.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

    return getMultiWordScore(queryWords, normText, tWords);
}
