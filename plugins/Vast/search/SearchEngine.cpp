#include "SearchEngine.hpp"
#include "FuzzyMatcher.hpp"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <algorithm>
#include <cmath>

SearchEngine::SearchEngine(QObject* parent) : QObject(parent) {
    m_settings     = new QSettings("vast-shell", "myamusashi", this);
    m_fileProvider = new FileProvider(this);

    connect(m_fileProvider, &FileProvider::filesReady, this, [this](QList<SearchResult*> results) {
        QVariantList vl;
        vl.reserve(results.size());
        for (SearchResult* r : results) {
            r->setParent(this);
            vl.append(QVariant::fromValue(r));
        }
        emit filesReady(vl);
    });

    connect(m_fileProvider, &FileProvider::searchStarted, this, &SearchEngine::fileSearchStarted);

    loadHistory();
}

void SearchEngine::loadHistory() {
    m_history.clear();
    const QByteArray raw = m_settings->value("launchHistory").toByteArray();
    if (raw.isEmpty())
        return;

    const QJsonArray arr = QJsonDocument::fromJson(raw).array();
    for (const QJsonValue& v : arr) {
        const QJsonObject obj = v.toObject();
        HistoryEntry      e;
        e.id        = obj["id"].toString();
        e.timestamp = obj["timestamp"].toVariant().toLongLong();
        e.count     = obj["count"].toInt();
        if (!e.id.isEmpty())
            m_history.append(e);
    }
}

void SearchEngine::saveHistory() {
    QJsonArray arr;
    for (const HistoryEntry& e : m_history) {
        QJsonObject obj;
        obj["id"]        = e.id;
        obj["timestamp"] = e.timestamp;
        obj["count"]     = e.count;
        arr.append(obj);
    }
    m_settings->setValue("launchHistory", QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

double SearchEngine::recencyScore(const QString& appId) const {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    for (const HistoryEntry& e : m_history) {
        if (e.id == appId) {
            const double age       = static_cast<double>(now - e.timestamp);
            const double recency   = std::exp(-age / (86400000.0 * 7.0));
            const double frequency = std::min(e.count / 10.0, 1.0);
            return recency * 0.7 + frequency * 0.3;
        }
    }
    return 0.0;
}

double SearchEngine::scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery) const {
    const QString     name        = FuzzyMatcher::normalizeText(entry->property("name").toString());
    const QString     genericName = FuzzyMatcher::normalizeText(entry->property("genericName").toString());
    const QString     comment     = FuzzyMatcher::normalizeText(entry->property("comment").toString());

    const QStringList nameWords = name.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

    double nameScore = 0.0;
    if (name == normQuery)
        nameScore = 1.0;
    else if (name.contains(normQuery))
        nameScore = 0.95;
    else
        nameScore = FuzzyMatcher::getMultiWordScore(normQueryWords, name, nameWords);

    if (nameScore >= 0.9)
        return nameScore;

    double genericScore = 0.0;
    if (!genericName.isEmpty()) {
        const QStringList gWords = genericName.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        genericScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, genericName, gWords) * 0.7;
    }

    double commentScore = 0.0;
    if (!comment.isEmpty()) {
        const QStringList cWords = comment.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        commentScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, comment, cWords) * 0.5;
    }

    return std::max({nameScore, genericScore, commentScore});
}

QVariantList SearchEngine::searchApps(const QVariantList& apps, const QString& query) const {
    // No query: show all apps, recently launched ones sorted to the top.
    if (query.trimmed().isEmpty()) {
        QList<QPair<double, QVariant>> hits;
        hits.reserve(apps.size());
        for (const QVariant& v : apps) {
            QObject* entry = qvariant_cast<QObject*>(v);
            if (!entry)
                continue;
            const double r = recencyScore(entry->property("id").toString());
            hits.append({r, v});
        }
        // Stable sort: recency desc, then original order for ties (r == 0).
        std::stable_sort(hits.begin(), hits.end(), [](const QPair<double, QVariant>& a, const QPair<double, QVariant>& b) { return a.first > b.first; });
        QVariantList out;
        out.reserve(hits.size());
        for (const auto& h : hits)
            out.append(h.second);
        return out;
    }

    const QString     normQuery      = FuzzyMatcher::normalizeText(query).trimmed();
    const QStringList normQueryWords = normQuery.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

    struct Hit {
        double   score;
        QVariant variant;
        QString  name;
    };
    QList<Hit> hits;

    for (const QVariant& v : apps) {
        QObject* entry = qvariant_cast<QObject*>(v);
        if (!entry)
            continue;

        const double base = scoreApp(entry, normQueryWords, normQuery);
        if (base < m_appThreshold)
            continue;

        const double finalScore = base + recencyScore(entry->property("id").toString()) * FuzzyMatcher::kRecencyWeight;

        hits.append({finalScore, v, entry->property("name").toString()});
    }

    std::sort(hits.begin(), hits.end(), [](const Hit& a, const Hit& b) {
        if (std::abs(a.score - b.score) < 0.001)
            return a.name.length() < b.name.length();
        return a.score > b.score;
    });

    // return the original DesktopEntry* variants, delegate needs no changes
    QVariantList out;
    out.reserve(hits.size());
    for (const Hit& h : hits)
        out.append(h.variant);
    return out;
}

void SearchEngine::recordLaunch(const QString& appId) {
    const qint64 now   = QDateTime::currentMSecsSinceEpoch();
    bool         found = false;

    for (HistoryEntry& e : m_history) {
        if (e.id == appId) {
            e.timestamp = now;
            e.count     = e.count + 1;
            found       = true;
            break;
        }
    }

    if (!found)
        m_history.append({appId, now, 1});

    if (m_history.size() > m_historyLimit) {
        std::sort(m_history.begin(), m_history.end(), [](const HistoryEntry& a, const HistoryEntry& b) { return a.timestamp > b.timestamp; });
        m_history = m_history.mid(0, m_historyLimit);
    }

    saveHistory();
}

void SearchEngine::clearHistory() {
    m_history.clear();
    saveHistory();
}

void SearchEngine::searchFiles(const QString& query, const QString& rootDir, int maxDepth) {
    m_fileProvider->searchAsync(query, rootDir, maxDepth, m_fileThreshold);
}

QVariantList SearchEngine::searchFilesSync(const QString& query, const QString& rootDir, int maxDepth) const {
    const QList<SearchResult*> raw = m_fileProvider->searchSync(query, rootDir, maxDepth, m_fileThreshold);
    QVariantList               out;
    out.reserve(raw.size());
    for (SearchResult* r : raw)
        out.append(QVariant::fromValue(r));
    return out;
}

void SearchEngine::cancelFileSearch() {
    m_fileProvider->cancel();
}

// utils
QString SearchEngine::highlightedHtml(const QString& text, const QString& query, const QString& color) const {
    return FuzzyMatcher::highlightedHtml(text, query, color);
}

QVariantList SearchEngine::highlightRanges(const QString& text, const QString& query) const {
    return FuzzyMatcher::highlightRanges(text, query);
}

double SearchEngine::score(const QString& query, const QString& text) const {
    return FuzzyMatcher::fuzzyScore(query, text);
}
