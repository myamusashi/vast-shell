#include "FuzzyMatcher.hpp"
#include "SearchEngine.hpp"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>
#include <cmath>

SearchEngine::SearchEngine(QObject* parent) : QObject(parent) {
    m_settings     = new QSettings("vast-shell", "myamusashi", this);
    m_appProvider  = new AppProvider(this);
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
            const double age            = static_cast<double>(now - e.timestamp);
            const double dayMs          = 86400000.0;
            const double recencyScore   = std::exp(-age / (dayMs * 7.0));
            const double frequencyScore = std::min(e.count / 10.0, 1.0);
            return recencyScore * 0.7 + frequencyScore * 0.3;
        }
    }
    return 0.0;
}

QHash<QString, double> SearchEngine::recencyMap() const {
    QHash<QString, double> map;
    map.reserve(m_history.size());
    for (const HistoryEntry& e : m_history)
        map.insert(e.id, recencyScore(e.id));
    return map;
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

void SearchEngine::reloadApps() {
    m_appProvider->reload();
}

QVariantList SearchEngine::searchApps(const QString& query) const {
    const QList<SearchResult*> raw = m_appProvider->search(query, recencyMap(), m_appThreshold);
    QVariantList               out;
    out.reserve(raw.size());
    for (SearchResult* r : raw)
        out.append(QVariant::fromValue(r));
    return out;
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

QVariantList SearchEngine::search(const QString& query, const QString& fileRootDir, int fileMaxDepth) const {
    // apps are synchronous and fast
    QVariantList results = searchApps(query);

    // kick off async file search if a root dir is provided
    if (!fileRootDir.isEmpty())
        const_cast<SearchEngine*>(this)->searchFiles(query, fileRootDir, fileMaxDepth);

    return results;
}

QString SearchEngine::highlightedHtml(const QString& text, const QString& query, const QString& color) const {
    return FuzzyMatcher::highlightedHtml(text, query, color);
}

QVariantList SearchEngine::highlightRanges(const QString& text, const QString& query) const {
    return FuzzyMatcher::highlightRanges(text, query);
}

double SearchEngine::score(const QString& query, const QString& text) const {
    return FuzzyMatcher::fuzzyScore(query, text);
}
