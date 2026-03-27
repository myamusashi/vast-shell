#include "ClipboardModel.hpp"

#include <QDateTime>

#include <algorithm>

namespace Vast {

    ClipboardModel::ClipboardModel(QObject* parent) : QAbstractListModel{parent} {}

    int ClipboardModel::rowCount(const QModelIndex& parent) const {
        if (parent.isValid())
            return 0;
        return visibleCount();
    }

    QVariant ClipboardModel::data(const QModelIndex& index, int role) const {
        if (!index.isValid() || index.row() >= visibleCount())
            return {};

        const ClipboardEntry& e = visibleAt(index.row());

        switch (static_cast<Roles>(role)) {
            case IdRole: return e.id;
            case TypeRole: return e.typeString();
            case PreviewRole: return makePreview(e);
            case TimestampRole: return e.timestamp;
            case PinnedRole: return e.pinned;
            case SourceAppRole: return e.sourceApp;
            case MimeTypeRole: return e.mimeType;
            case SizeBytesRole: return e.sizeBytes;
        }
        return {};
    }

    QHash<int, QByteArray> ClipboardModel::roleNames() const {
        return {
            {IdRole, "entryId"},    {TypeRole, "type"},           {PreviewRole, "preview"},   {TimestampRole, "timestamp"},
            {PinnedRole, "pinned"}, {SourceAppRole, "sourceApp"}, {MimeTypeRole, "mimeType"}, {SizeBytesRole, "sizeBytes"},
        };
    }

    void ClipboardModel::reset(QList<ClipboardEntry> entries) {
        beginResetModel();
        m_entries     = std::move(entries);
        m_filtering   = false;
        m_filterQuery = {};
        m_filtered.clear();
        endResetModel();
        emit countChanged();
    }

    void ClipboardModel::prepend(const ClipboardEntry& entry) {
        const int existing = indexById(entry.id);
        if (existing >= 0) {
            if (!m_filtering) {
                beginRemoveRows({}, existing, existing);
                m_entries.removeAt(existing);
                endRemoveRows();
            } else
                m_entries.removeAt(existing);
        }
        const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
            if (entry.pinned && !e.pinned)
                return true;
            if (!entry.pinned && e.pinned)
                return false;
            return entry.timestamp >= e.timestamp;
        });

        const int  rawRow = static_cast<int>(std::distance(m_entries.begin(), insertPos));
        m_entries.insert(insertPos, entry);

        if (m_filtering) {
            rebuildFilter();
            emit countChanged();
        } else {
            beginInsertRows({}, rawRow, rawRow);
            endInsertRows();
            emit countChanged();
        }
    }

    void ClipboardModel::removeById(qint64 id) {
        const int idx = indexById(id);
        if (idx < 0)
            return;

        if (m_filtering) {
            m_entries.removeAt(idx);
            rebuildFilter();
            emit countChanged();
        } else {
            beginRemoveRows({}, idx, idx);
            m_entries.removeAt(idx);
            endRemoveRows();
            emit countChanged();
        }
    }

    void ClipboardModel::setPinById(qint64 id, bool pinned) {
        const int idx = indexById(id);
        if (idx < 0)
            return;

        m_entries[idx].pinned = pinned;

        std::ranges::stable_sort(m_entries, [](const ClipboardEntry& a, const ClipboardEntry& b) {
            if (a.pinned != b.pinned)
                return a.pinned > b.pinned;
            return a.timestamp > b.timestamp;
        });

        if (m_filtering) {
            rebuildFilter();
        } else {
            beginResetModel();
            endResetModel();
        }
        emit countChanged();
    }

    void ClipboardModel::setFilter(const QString& query) {
        m_filterQuery = query;
        m_filtering   = !query.isEmpty();
        rebuildFilter();
        emit countChanged();
    }

    void ClipboardModel::rebuildFilter() {
        m_filtered.clear();

        if (!m_filtering)
            return;

        const QString lower = m_filterQuery.toLower();

        // ClipboardManager may swap this for FuzzyMatcher
        // scoring once the fuzzy layer is wired up, but the model itself stays
        // unaware of the matching algorithm.
        for (int i = 0; i < m_entries.size(); ++i) {
            const ClipboardEntry& e       = m_entries[i];
            const bool            matches = e.content.toLower().contains(lower) || e.sourceApp.toLower().contains(lower) || e.mimeType.toLower().contains(lower);
            if (matches)
                m_filtered.append(i);
        }
    }

    qint64 ClipboardModel::idAtRow(int row) const {
        if (row < 0 || row >= visibleCount())
            return -1;
        return visibleAt(row).id;
    }

    const ClipboardEntry& ClipboardModel::visibleAt(int row) const {
        return m_filtering ? m_entries[m_filtered[row]] : m_entries[row];
    }

    int ClipboardModel::visibleCount() const {
        return m_filtering ? static_cast<int>(m_filtered.size()) : static_cast<int>(m_entries.size());
    }

    int ClipboardModel::indexById(qint64 id) const {
        const auto it = std::ranges::find_if(m_entries, [id](const ClipboardEntry& e) { return e.id == id; });
        if (it == m_entries.end())
            return -1;
        return static_cast<int>(std::distance(m_entries.begin(), it));
    }

    QString ClipboardModel::makePreview(const ClipboardEntry& e) {
        if (e.isImage())
            return {}; // QML delegate shows thumbnail via fullEntry() instead

        constexpr int kMaxChars = 120;

        const QString collapsed = e.content.simplified();
        return collapsed.length() > kMaxChars ? collapsed.left(kMaxChars) + QStringLiteral("…") : collapsed;
    }
}
