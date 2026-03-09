#include "AppProvider.hpp"
#include "FuzzyMatcher.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>
#include <cmath>
#include <qdir.h>
#include <qtypes.h>

AppProvider::AppProvider(QObject* parent) : QObject(parent) {
    reload();
}

void AppProvider::reload() {
    m_entries.clear();

    QStringList appDirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);
    QStringList seen;
    for (const QString& dir : appDirs) {
        if (!seen.contains(dir))
            seen.append(dir);
    }

    QSet<QString> loadedIds;
    for (const QString& dir : seen) {
        QDirIterator it(dir, {"*.desktop"}, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            it.next();
            const QString id = it.fileInfo().fileName();
            if (!loadedIds.contains(id)) {
                parseDesktopFile(it.filePath());
                loadedIds.insert(id);
            }
        }
    }

    emit reloaded();
}

void AppProvider::parseDesktopFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    AppEntry entry;
    entry.id = QFileInfo(path).fileName();

    bool        inDesktopEntry = false;
    QTextStream in(&file);

    while (!in.atEnd()) {
        const QString raw  = in.readLine();
        const QString line = raw.trimmed();

        if (line.startsWith('[')) {
            inDesktopEntry = (line == "[Desktop Entry]");
            continue;
        }
        if (!inDesktopEntry || line.startsWith('#') || line.isEmpty())
            continue;

        qsizetype eq = line.indexOf('=');
        if (eq < 0)
            continue;

        const QString key   = line.left(eq).trimmed();
        const QString value = line.mid(eq + 1).trimmed();

        if (key.contains('['))
            continue;

        if (key == "Name")
            entry.name = value;
        else if (key == "GenericName")
            entry.genericName = value;
        else if (key == "Comment")
            entry.comment = value;
        else if (key == "Exec")
            entry.exec = value;
        else if (key == "TryExec")
            entry.tryExec = value;
        else if (key == "Icon")
            entry.icon = value;
        else if (key == "Categories")
            entry.categories = value.split(';', Qt::SkipEmptyParts);
        else if (key == "Keywords")
            entry.keywords = value.split(';', Qt::SkipEmptyParts);
        else if (key == "NoDisplay")
            entry.noDisplay = (value.toLower() == "true");
        else if (key == "Terminal")
            entry.terminal = (value.toLower() == "true");
    }

    if (entry.name.isEmpty() || entry.noDisplay)
        return;

    entry.normName      = FuzzyMatcher::normalizeText(entry.name);
    entry.normGeneric   = FuzzyMatcher::normalizeText(entry.genericName);
    entry.normComment   = FuzzyMatcher::normalizeText(entry.comment);
    entry.normNameWords = entry.normName.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

    m_entries.append(std::move(entry));
}

double AppProvider::scoreEntry(const AppEntry& e, const QStringList& normQueryWords, const QString& normQuery) const {
    double nameScore = 0.0;
    if (e.normName == normQuery)
        nameScore = 1.0;
    else if (e.normName.contains(normQuery))
        nameScore = 0.95;
    else
        nameScore = FuzzyMatcher::getMultiWordScore(normQueryWords, e.normName, e.normNameWords);

    if (nameScore >= 0.9)
        return nameScore;

    double genericScore = 0.0;
    if (!e.normGeneric.isEmpty()) {
        const QStringList gWords = e.normGeneric.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        genericScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, e.normGeneric, gWords) * 0.7;
    }

    double commentScore = 0.0;
    if (!e.normComment.isEmpty()) {
        const QStringList cWords = e.normComment.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        commentScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, e.normComment, cWords) * 0.5;
    }

    return std::max({nameScore, genericScore, commentScore});
}

QList<SearchResult*> AppProvider::search(const QString& query, const QHash<QString, double>& recencyScores, double threshold) const {
    if (query.trimmed().isEmpty()) {
        QList<SearchResult*> results;
        for (const AppEntry& e : m_entries) {
            const double recency = recencyScores.value(e.id, 0.0);
            if (recency <= 0.0)
                continue;

            QVariantMap data;
            data["id"]       = e.id;
            data["exec"]     = e.exec;
            data["terminal"] = e.terminal;

            results.append(SearchResult::makeApp(e.name, e.genericName, e.icon, recency * FuzzyMatcher::kRecencyWeight, data, {}, nullptr));
        }
        std::sort(results.begin(), results.end(), [](SearchResult* a, SearchResult* b) { return a->score() > b->score(); });
        return results;
    }

    const QString     normQuery      = FuzzyMatcher::normalizeText(query).trimmed();
    const QStringList normQueryWords = normQuery.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

    struct Hit {
        const AppEntry* entry;
        double          score;
    };
    QList<Hit> hits;

    for (const AppEntry& e : m_entries) {
        double base = scoreEntry(e, normQueryWords, normQuery);
        if (base < threshold)
            continue;

        const double recency = recencyScores.value(e.id, 0.0);
        const double final   = base + recency * FuzzyMatcher::kRecencyWeight;
        hits.append({&e, final});
    }

    std::sort(hits.begin(), hits.end(), [](const Hit& a, const Hit& b) {
        if (std::abs(a.score - b.score) < 0.001)
            return a.entry->name.length() < b.entry->name.length();
        return a.score > b.score;
    });

    QList<SearchResult*> results;
    results.reserve(hits.size());

    for (const Hit& h : hits) {
        const AppEntry& e = *h.entry;

        QVariantMap     data;
        data["id"]         = e.id;
        data["exec"]       = e.exec;
        data["terminal"]   = e.terminal;
        data["categories"] = e.categories;

        const QVariantList ranges = FuzzyMatcher::highlightRanges(e.name, query);

        results.append(SearchResult::makeApp(e.name, e.genericName, e.icon, h.score, data, ranges, nullptr));
    }

    return results;
}
