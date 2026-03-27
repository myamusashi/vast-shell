#include "ClipboardDatabase.hpp"

#include <QDateTime>
#include <QSqlError>
#include <QSqlQuery>
#include <QUuid>
#include <QVariant>

namespace Vast {

    ClipboardDatabase::ClipboardDatabase(QObject* parent) : QObject{parent} {
        m_connectionName = QStringLiteral("VastClipboard_") % QUuid::createUuid().toString(QUuid::WithoutBraces);
    }

    ClipboardDatabase::~ClipboardDatabase() {
        close();
    }

    std::expected<void, QString> ClipboardDatabase::open(const QString& dbPath) {
        if (m_open)
            return std::unexpected(QStringLiteral("Database already open"));

        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
        m_db.setDatabaseName(dbPath);

        if (!m_db.open())
            return std::unexpected(lastError());

        QSqlQuery pragma{m_db};
        pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
        pragma.exec(QStringLiteral("PRAGMA foreign_keys=ON"));
        pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));

        if (auto result = createSchema(); !result)
            return std::unexpected(result.error());

        m_open = true;
        return {};
    }

    void ClipboardDatabase::close() {
        if (!m_open)
            return;

        m_db.close();
        QSqlDatabase::removeDatabase(m_connectionName);
        m_open = false;
    }

    bool ClipboardDatabase::isOpen() const noexcept {
        return m_open && m_db.isOpen();
    }

    std::expected<void, QString> ClipboardDatabase::createSchema() {
        QSqlQuery  q{m_db};

        const bool ok = q.exec(QStringLiteral(R"sql(
			CREATE TABLE IF NOT EXISTS clipboard_entries (
				id          INTEGER PRIMARY KEY AUTOINCREMENT,
				type        TEXT    NOT NULL,
				content     TEXT,
				data        BLOB,
				mime_type   TEXT    NOT NULL DEFAULT '',
				hash        TEXT    NOT NULL UNIQUE,
				pinned      INTEGER NOT NULL DEFAULT 0,
				source_app  TEXT             DEFAULT '',
				size_bytes  INTEGER NOT NULL DEFAULT 0,
				timestamp   INTEGER NOT NULL
			);
		)sql"));

        if (!ok)
            return std::unexpected(lastError());

        const std::array indices = {
            QStringLiteral("CREATE INDEX IF NOT EXISTS idx_ts ON clipboard_entries(timestamp DESC)"),
            QStringLiteral("CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_entries(pinned, timestamp DESC)"),
            QStringLiteral("CREATE INDEX IF NOT EXISTS idx_hash ON clipboard_entries(hash)"),
        };

        for (const auto& ddl : indices)
            if (!q.exec(ddl))
                return std::unexpected(lastError());

        return {};
    }

    std::expected<qint64, QString> ClipboardDatabase::insert(const ClipboardEntry& entry) {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        if (existsByHash(entry.hash)) {
            QSqlQuery bump{m_db};
            bump.prepare(QStringLiteral("UPDATE clipboard_entries SET timestamp = :ts WHERE hash = :hash"));
            bump.bindValue(QStringLiteral(":ts"), QDateTime::currentMSecsSinceEpoch());
            bump.bindValue(QStringLiteral(":hash"), QString::fromLatin1(entry.hash.toHex()));
            bump.exec();
            // Return -1 as a sentinel: "not inserted, was duplicate"
            return -1LL;
        }

        QSqlQuery q{m_db};
        q.prepare(QStringLiteral(R"sql(
			INSERT INTO clipboard_entries
				(type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp)
			VALUES
				(:type, :content, :data, :mime_type, :hash, :pinned, :source_app, :size_bytes, :timestamp)
		)sql"));

        q.bindValue(QStringLiteral(":type"), entry.typeString());
        q.bindValue(QStringLiteral(":content"), entry.content);
        q.bindValue(QStringLiteral(":data"), entry.data.isEmpty() ? QVariant{QMetaType{QMetaType::QByteArray}} : QVariant{entry.data});
        q.bindValue(QStringLiteral(":mime_type"), entry.mimeType);
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(entry.hash.toHex()));
        q.bindValue(QStringLiteral(":pinned"), entry.pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":source_app"), entry.sourceApp);
        q.bindValue(QStringLiteral(":size_bytes"), entry.sizeBytes);
        q.bindValue(QStringLiteral(":timestamp"), entry.timestamp > 0 ? entry.timestamp : QDateTime::currentMSecsSinceEpoch());

        if (!q.exec())
            return std::unexpected(lastError());

        const qint64   newId = q.lastInsertId().toLongLong();

        ClipboardEntry inserted = entry;
        inserted.id             = newId;

        emit entryInserted(inserted);

        return newId;
    }

    std::expected<void, QString> ClipboardDatabase::remove(qint64 id) {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{m_db};
        q.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE id = :id"));
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryRemoved(id);
        return {};
    }

    std::expected<void, QString> ClipboardDatabase::setPin(qint64 id, bool pinned) {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{m_db};
        q.prepare(QStringLiteral("UPDATE clipboard_entries SET pinned = :pinned WHERE id = :id"));
        q.bindValue(QStringLiteral(":pinned"), pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryPinChanged(id, pinned);
        return {};
    }

    std::expected<void, QString> ClipboardDatabase::clearUnpinned() {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{m_db};
        if (!q.exec(QStringLiteral("DELETE FROM clipboard_entries WHERE pinned = 0")))
            return std::unexpected(lastError());

        return {};
    }

    std::expected<void, QString> ClipboardDatabase::pruneToLimit(int maxEntries, qint64 maxBytes) {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        // 1. enforce entry count limit
        if (maxEntries > 0) {
            QSqlQuery countQ{m_db};
            countQ.exec(QStringLiteral("SELECT COUNT(*) FROM clipboard_entries WHERE pinned = 0"));
            if (countQ.next()) {
                const int unpinnedCount = countQ.value(0).toInt();
                const int excess        = unpinnedCount - maxEntries;
                if (excess > 0) {
                    QSqlQuery pruneQ{m_db};
                    pruneQ.prepare(QStringLiteral(R"sql(
                    DELETE FROM clipboard_entries
                    WHERE id IN (
                        SELECT id FROM clipboard_entries
                        WHERE pinned = 0
                        ORDER BY timestamp ASC
                        LIMIT :excess
                    )
                )sql"));
                    pruneQ.bindValue(QStringLiteral(":excess"), excess);
                    if (!pruneQ.exec())
                        return std::unexpected(lastError());
                }
            }
        }

        // 2. enforce byte-size limit (outer loop, prune one row at a time so we don't overshoot by deleting too many)
        if (maxBytes > 0) {
            while (true) {
                auto sizeResult = totalSizeBytes();
                if (!sizeResult)
                    return std::unexpected(sizeResult.error());

                if (*sizeResult <= maxBytes)
                    break;

                QSqlQuery  pruneQ{m_db};
                const bool ok = pruneQ.exec(QStringLiteral(R"sql(
					DELETE FROM clipboard_entries
					WHERE id = (
						SELECT id FROM clipboard_entries
						WHERE pinned = 0
						ORDER BY timestamp ASC
						LIMIT 1
					)
				)sql"));

                if (!ok)
                    return std::unexpected(lastError());

                if (pruneQ.numRowsAffected() == 0)
                    break;
            }
        }

        return {};
    }

    bool ClipboardDatabase::existsByHash(const QByteArray& hash) {
        if (!m_open)
            return false;

        QSqlQuery q{m_db};
        q.prepare(QStringLiteral("SELECT 1 FROM clipboard_entries WHERE hash = :hash LIMIT 1"));
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(hash.toHex()));
        q.exec();
        return q.next();
    }

    std::expected<QList<ClipboardEntry>, QString> ClipboardDatabase::fetchAll() {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery  q{m_db};
        const bool ok = q.exec(QStringLiteral(R"sql(
			SELECT id, type, content, mime_type, hash, pinned, source_app, size_bytes, timestamp
			FROM clipboard_entries
			ORDER BY pinned DESC, timestamp DESC
		)sql"));

        if (!ok)
            return std::unexpected(lastError());

        QList<ClipboardEntry> entries;
        while (q.next())
            entries.append(rowToEntry(q, /*includeData=*/false));

        return entries;
    }

    std::expected<ClipboardEntry, QString> ClipboardDatabase::fetchById(qint64 id) {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{m_db};
        q.prepare(QStringLiteral(R"sql(
			SELECT id, type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp
			FROM clipboard_entries
			WHERE id = :id
			LIMIT 1
		)sql"));
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        if (!q.next())
            return std::unexpected(QStringLiteral("No entry found with id %1").arg(id));

        return rowToEntry(q, /*includeData=*/true);
    }

    std::expected<qint64, QString> ClipboardDatabase::totalSizeBytes() {
        if (!m_open)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{m_db};
        if (!q.exec(QStringLiteral("SELECT COALESCE(SUM(size_bytes), 0) FROM clipboard_entries")))
            return std::unexpected(lastError());

        if (!q.next())
            return 0LL;

        return q.value(0).toLongLong();
    }

    ClipboardEntry ClipboardDatabase::rowToEntry(const QSqlQuery& q, bool includeData) {
        ClipboardEntry e;

        // When includeData is true, column 3 is 'data' and shifts subsequent columns by 1.
        const int off = includeData ? 1 : 0;

        e.id      = q.value(0).toLongLong();
        e.type    = ClipboardEntry::typeFromString(q.value(1).toString());
        e.content = q.value(2).toString();
        if (includeData)
            e.data = q.value(3).toByteArray();
        e.mimeType  = q.value(3 + off).toString();
        e.hash      = QByteArray::fromHex(q.value(4 + off).toString().toLatin1());
        e.pinned    = q.value(5 + off).toInt() != 0;
        e.sourceApp = q.value(6 + off).toString();
        e.sizeBytes = q.value(7 + off).toLongLong();
        e.timestamp = q.value(8 + off).toLongLong();

        return e;
    }

    QString ClipboardDatabase::lastError() const {
        return m_db.lastError().text();
    }
}
