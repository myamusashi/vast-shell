#pragma once

#include "ClipboardEntry.hpp"

#include <QAbstractListModel>
#include <QtQml/qqmlregistration.h>

namespace Vast {

    // Two lists are maintained:
    //   m_entries   — full list, source of truth
    //   m_filtered  — indices into m_entries, rebuilt on search()
    //
    // The model exposes m_filtered when a search query is active, m_entries
    // otherwise, so the ListView never needs to know about filtering

    class ClipboardModel : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via ClipboardManager.model")
        Q_DISABLE_COPY(ClipboardModel)

        Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

      public:
        enum Roles {
            IdRole = Qt::UserRole,
            TypeRole,      // "text" | "html" | "image" | "files"
            PreviewRole,   // truncated text snippet or empty for images
            TimestampRole,
            PinnedRole,
            SourceAppRole,
            MimeTypeRole,
            SizeBytesRole,
        };
        Q_ENUM(Roles)

        explicit ClipboardModel(QObject* parent = nullptr);
        ~ClipboardModel() override = default;

        [[nodiscard]] int                    rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

        // Populate from initial DB fetch
        void reset(QList<ClipboardEntry> entries);

        // Prepend a newly-inserted entry and re-sort
        void prepend(const ClipboardEntry& entry);

        void removeById(qint64 id);

        // Update pinned state of an entry
        void setPinById(qint64 id, bool pinned);

        // Filter by fuzzy query string. Pass empty string to clear filter
        void setFilter(const QString& query);

        // Return entry id at the given visible row (respects current filter)
        [[nodiscard]] Q_INVOKABLE qint64 idAtRow(int row) const;

      signals:
        void countChanged();

      private:
        // Returns a short preview string (≤ 120 chars) for the role
        [[nodiscard]] static QString makePreview(const ClipboardEntry& e);

        // Finds the index in m_entries by id. Returns -1 if not found
        [[nodiscard]] int indexById(qint64 id) const;

        // Rebuilds m_filtered from m_entries based on m_filterQuery
        void rebuildFilter();

        // The current visible list (pointer into m_entries or filtered subset)
        [[nodiscard]] const ClipboardEntry& visibleAt(int row) const;
        [[nodiscard]] int                   visibleCount() const;

        QList<ClipboardEntry> m_entries{};
        QList<int>            m_filtered{}; // indices into m_entries
        QString               m_filterQuery{};
        bool                  m_filtering = false;
    };
}
