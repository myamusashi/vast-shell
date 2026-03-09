#pragma once

#include "AppProvider.hpp"
#include "FileProvider.hpp"

#include <QHash>
#include <QList>
#include <QObject>
#include <QQmlEngine>
#include <QSettings>
#include <QString>
#include <QVariantList>
#include <qnumeric.h>

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

    Q_INVOKABLE QVariantList searchApps(const QString& query) const;
    Q_INVOKABLE void         reloadApps();

    Q_INVOKABLE void         searchFiles(const QString& query, const QString& rootDir, int maxDepth = 3);
    Q_INVOKABLE QVariantList searchFilesSync(const QString& query, const QString& rootDir, int maxDepth = 2) const;
    Q_INVOKABLE void         cancelFileSearch();

    Q_INVOKABLE QVariantList search(const QString& query, const QString& fileRootDir = "", int fileMaxDepth = 2) const;

    Q_INVOKABLE void         recordLaunch(const QString& appId);
    Q_INVOKABLE double       recencyScore(const QString& appId) const;
    Q_INVOKABLE void         clearHistory();

    Q_INVOKABLE QString      highlightedHtml(const QString& text, const QString& query, const QString& color) const;
    Q_INVOKABLE QVariantList highlightRanges(const QString& text, const QString& query) const;
    Q_INVOKABLE double       score(const QString& query, const QString& text) const;

    int                      historyLimit() const {
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
        if (qFuzzyCompare(m_appThreshold, v)) {
            m_appThreshold = v;
            emit appThresholdChanged();
        }
    }
    void setFileThreshold(double v) {
        if (qFuzzyCompare(m_fileThreshold, v)) {
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

    QHash<QString, double> recencyMap() const;

    AppProvider*           m_appProvider  = nullptr;
    FileProvider*          m_fileProvider = nullptr;
    QSettings*             m_settings     = nullptr;

    QList<HistoryEntry>    m_history;
    int                    m_historyLimit  = 50;
    double                 m_appThreshold  = 0.35;
    double                 m_fileThreshold = 0.40;
};
