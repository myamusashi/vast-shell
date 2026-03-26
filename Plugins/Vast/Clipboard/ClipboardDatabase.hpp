#pragma once

#include "ClipboardEntry.hpp"

#include <QObject>
#include <QSqlDatabase>
#include <QString>

#include <expected>

namespace Vast {

    class ClipboardDatabase : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(ClipboardDatabase)

      public:
        explicit ClipboardDatabase(QObject* parent = nullptr);
        ~ClipboardDatabase() override;

        [[nodiscard]] std::expected<void, QString> open(const QString& dbPath);
        void                                       close();
        [[nodiscard]] bool                         isOpen() const noexcept;

        // returns the new row id, or std::unexpected on error
        [[nodiscard]] std::expected<qint64, QString> insert(const ClipboardEntry& entry);
        // hard-delete a single row
        [[nodiscard]] std::expected<void, QString> remove(qint64 id);

        [[nodiscard]] std::expected<void, QString> setPin(qint64 id, bool pinned);
        [[nodiscard]] std::expected<void, QString> clearUnpinned();

        [[nodiscard]] std::expected<void, QString> pruneToLimit(int maxEntries, qint64 maxBytes);

        // entry to avoid heavy BLOB insert on duplicate copy events
        [[nodiscard]] bool existsByHash(const QByteArray& hash);

        // fetch all entries ordered by pinned DESC, timestamp DESC
        // Data (BLOB) is NOT loaded here, use fetchById for full preview
        [[nodiscard]] std::expected<QList<ClipboardEntry>, QString> fetchAll();

        // fetch a single entry including the BLOB, for preview panel
        [[nodiscard]] std::expected<ClipboardEntry, QString> fetchById(qint64 id);

        // return total size_bytes of all rows combined
        [[nodiscard]] std::expected<qint64, QString> totalSizeBytes();

      signals:
        void entryInserted(Vast::ClipboardEntry entry);
        void entryRemoved(qint64 id);
        void entryPinChanged(qint64 id, bool pinned);

      private:
        [[nodiscard]] std::expected<void, QString> createSchema();
        [[nodiscard]] static ClipboardEntry        rowToEntry(const QSqlQuery& q, bool includeData = false);
        [[nodiscard]] QString                      lastError() const;

        QSqlDatabase                               m_db{};
        QString                                    m_connectionName{};
        bool                                       m_open = false;
    };
}
