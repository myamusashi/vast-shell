#pragma once

#include "FileProvider.hpp"
#include "FuzzyMatcher.hpp"
#include "SearchResult.hpp"

#include <QHash>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QSettings>
#include <QString>
#include <QVariantList>

// ---------------------------------------------------------------------------
// SearchEngine  — QML Singleton (URI: Vast)
//
// Unified app + file fuzzy search with launch-history recency ranking.
// The app list is owned by Quickshell (DesktopEntries.applications.values)
// and passed in directly, so no internal .desktop scanning is needed.
//
// QML:
//   import Vast
//
//   // Apps — pass Quickshell's list directly
//   var apps = SearchEngine.searchApps(DesktopEntries.applications.values, "fire")
//
//   // Files — async, listen to filesReady()
//   SearchEngine.searchFiles("resume", "/home/user", 3)
//
//   // Record launch for recency ranking
//   SearchEngine.recordLaunch(entry.id)
//
//   // Utilities
//   SearchEngine.highlightedHtml(text, query, "#88c0d0")
//   SearchEngine.score("frf", "Firefox")  // → 0..1
// ---------------------------------------------------------------------------
class SearchEngine : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int historyLimit READ historyLimit WRITE setHistoryLimit NOTIFY historyLimitChanged)
    Q_PROPERTY(double appThreshold READ appThreshold WRITE setAppThreshold NOTIFY appThresholdChanged)
    Q_PROPERTY(double fileThreshold READ fileThreshold WRITE setFileThreshold NOTIFY fileThresholdChanged)

  public:
    static SearchEngine* create(QQmlEngine*, QJSEngine*) {
        auto* inst = new SearchEngine();
        QQmlEngine::setObjectOwnership(inst, QQmlEngine::CppOwnership);
        return inst;
    }

    // ── App search ────────────────────────────────────────────────────────────
    // apps    — DesktopEntries.applications.values (QVariantList of DesktopEntry*)
    // query   — raw search text from the user
    //
    // Each DesktopEntry is read via QObject::property() for:
    //   "id", "name", "genericName", "comment", "icon"
    // Returns the original DesktopEntry* objects sorted by score, so the
    // existing delegate (modelData.name, modelData.icon, etc.) needs no changes.
    Q_INVOKABLE QVariantList searchApps(const QVariantList& apps, const QString& query) const;

    // ── File search ───────────────────────────────────────────────────────────
    Q_INVOKABLE void         searchFiles(const QString& query, const QString& rootDir, int maxDepth = 3);
    Q_INVOKABLE QVariantList searchFilesSync(const QString& query, const QString& rootDir, int maxDepth = 2) const;
    Q_INVOKABLE void         cancelFileSearch();

    // ── Launch history ────────────────────────────────────────────────────────
    Q_INVOKABLE void   recordLaunch(const QString& appId);
    Q_INVOKABLE double recencyScore(const QString& appId) const;
    Q_INVOKABLE void   clearHistory();

    // ── Highlight / score utilities ───────────────────────────────────────────
    Q_INVOKABLE QString      highlightedHtml(const QString& text, const QString& query, const QString& color) const;
    Q_INVOKABLE QVariantList highlightRanges(const QString& text, const QString& query) const;
    Q_INVOKABLE double       score(const QString& query, const QString& text) const;

    // ── Properties ────────────────────────────────────────────────────────────
    int historyLimit() const {
        return m_historyLimit;
    }
    double appThreshold() const {
        return m_appThreshold;
    }
    double fileThreshold() const {
        return m_fileThreshold;
    }

    void setHistoryLimit(int v) {
        if (m_historyLimit != v) {
            m_historyLimit = v;
            emit historyLimitChanged();
        }
    }
    void setAppThreshold(double v) {
        if (m_appThreshold != v) {
            m_appThreshold = v;
            emit appThresholdChanged();
        }
    }
    void setFileThreshold(double v) {
        if (m_fileThreshold != v) {
            m_fileThreshold = v;
            emit fileThresholdChanged();
        }
    }

  signals:
    void filesReady(QVariantList results);
    void fileSearchStarted();

    void historyLimitChanged();
    void appThresholdChanged();
    void fileThresholdChanged();

  private:
    explicit SearchEngine(QObject* parent = nullptr);

    void loadHistory();
    void saveHistory();

    struct HistoryEntry {
        QString id;
        qint64  timestamp = 0;
        int     count     = 0;
    };

    // Score a single DesktopEntry QObject against a pre-normalised query.
    double              scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery) const;

    FileProvider*       m_fileProvider = nullptr;
    QSettings*          m_settings     = nullptr;

    QList<HistoryEntry> m_history;
    int                 m_historyLimit  = 50;
    double              m_appThreshold  = 0.35;
    double              m_fileThreshold = 0.40;
};
