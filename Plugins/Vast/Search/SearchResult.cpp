#include "SearchResult.hpp"
#include "FuzzyMatcher.hpp"

SearchResult* SearchResult::makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                     QObject* parent) {
    auto* r              = new SearchResult(parent);
    r->m_type            = QStringLiteral("file");
    r->m_title           = title;
    r->m_subtitle        = subtitle;
    r->m_icon            = icon;
    r->m_score           = score;
    r->m_data            = data;
    r->m_highlightRanges = ranges;
    return r;
}

QString SearchResult::highlightedTitle(const QString& color) const {
    if (m_highlightRanges.isEmpty())
        return FuzzyMatcher::escapeHtml(m_title);

    QString result;
    int     last = 0;

    for (const QVariant& rv : m_highlightRanges) {
        const auto rm     = rv.toMap();
        const auto start  = rm.value("start").toInt();
        const auto length = rm.value("length").toInt();

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
