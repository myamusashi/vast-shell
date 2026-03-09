#include "SearchResult.hpp"
#include "FuzzyMatcher.hpp"

SearchResult* SearchResult::makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                     QObject* parent) {
    auto* r = new SearchResult(parent);
    r->setType("file");
    r->setTitle(title);
    r->setSubtitle(subtitle);
    r->setIcon(icon);
    r->setScore(score);
    r->setData(data);
    r->setHighlightRanges(ranges);
    return r;
}

QString SearchResult::highlightedTitle(const QString& color) const {
    if (m_highlightRanges.isEmpty())
        return FuzzyMatcher::escapeHtml(m_title);

    QString result;
    int     last = 0;

    for (const QVariant& rv : m_highlightRanges) {
        const QVariantMap rm     = rv.toMap();
        const int         start  = rm.value("start").toInt();
        const int         length = rm.value("length").toInt();

        if (start > last)
            result += FuzzyMatcher::escapeHtml(m_title.mid(last, start - last));

        result += QStringLiteral("<span style=\"color:%1;font-weight:600;\">").arg(color);
        result += FuzzyMatcher::escapeHtml(m_title.mid(start, length));
        result += QStringLiteral("</span>");

        last = start + length;
    }

    if (last < m_title.length())
        result += FuzzyMatcher::escapeHtml(m_title.mid(last));

    return result;
}
