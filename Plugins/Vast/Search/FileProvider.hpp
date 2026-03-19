#pragma once

#include "SearchResult.hpp"

#include <QFutureWatcher>
#include <QList>
#include <QMimeDatabase>
#include <QObject>
#include <QString>

class FileProvider : public QObject {
    Q_OBJECT

  public:
    explicit FileProvider(QObject* parent = nullptr);
    ~FileProvider() override;

    void                               searchAsync(const QString& query, const QString& rootDir, int maxDepth = 3, double threshold = 0.40);
    [[nodiscard]] QList<SearchResult*> searchSync(const QString& query, const QString& rootDir, int maxDepth = 2, double threshold = 0.40) const;
    void                               cancel();

  signals:
    void filesReady(QList<SearchResult*> results);
    void searchStarted();

  private:
    struct FileEntry {
        QString name;
        QString path;
        bool    isDir = false;
        QString mimeType;
        QString icon;
    };

    static QList<FileEntry>               collectFiles(const QString& rootDir, int maxDepth);
    static QString                        mimeIcon(const QString& mimeType, bool isDir);

    QList<SearchResult*>                  scoreEntries(const QList<FileEntry>& entries, const QString& query, double threshold, QObject* parent) const;

    QFutureWatcher<QList<SearchResult*>>* m_watcher = nullptr;
};
