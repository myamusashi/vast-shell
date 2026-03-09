#pragma once

#include "SearchResult.hpp"

#include <QHash>
#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>
#include <QDirIterator>

class AppProvider : public QObject {
    Q_OBJECT

  public:
    explicit AppProvider(QObject* parent = nullptr);

    Q_INVOKABLE void     reload();

    QList<SearchResult*> search(const QString& query, const QHash<QString, double>& recencyScores = {}, double threshold = 0.35) const;

    qsizetype            entryCount() const {
        return m_entries.size();
    }

  signals:
    void reloaded();

  private:
    struct AppEntry {
        QString     id;
        QString     name;
        QString     genericName;
        QString     comment;
        QString     exec;
        QString     tryExec;
        QString     icon;
        QStringList categories;
        QStringList keywords;
        bool        noDisplay = false;
        bool        terminal  = false;

        QString     normName;
        QString     normGeneric;
        QString     normComment;
        QStringList normNameWords;
    };

    void            parseDesktopFile(const QString& path);
    double          scoreEntry(const AppEntry& e, const QStringList& normQueryWords, const QString& normQuery) const;

    QList<AppEntry> m_entries;
};
