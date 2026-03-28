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
        if (m_filtering) {
            beginResetModel();
            const int existing = indexById(entry.id);
            if (existing >= 0)
                m_entries.removeAt(existing);

            const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
                if (entry.pinned && !e.pinned)
                    return true;
                if (!entry.pinned && e.pinned)
                    return false;
                return entry.timestamp >= e.timestamp;
            });

            m_entries.insert(insertPos, entry);
            rebuildFilter();
            endResetModel();
            emit countChanged();
            return;
        }

        const int existing = indexById(entry.id);
        if (existing >= 0) {
            // Find insertion point, skipping the existing item so distance is calculated
            // as if it was already removed, but iterators reflect current memory.
            const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
                if (e.id == entry.id)
                    return false;
                if (entry.pinned && !e.pinned)
                    return true;
                if (!entry.pinned && e.pinned)
                    return false;
                return entry.timestamp >= e.timestamp;
            });

            const int  dest = static_cast<int>(std::distance(m_entries.begin(), insertPos));

            if (existing != dest) {
                int destChild = dest > existing ? dest + 1 : dest;
                beginMoveRows({}, existing, existing, {}, destChild);
                auto item = m_entries.takeAt(existing);

                int  insertIdx = dest > existing ? dest - 1 : dest;
                item.timestamp = entry.timestamp;
                m_entries.insert(insertIdx, std::move(item));
                endMoveRows();
                emit dataChanged(index(insertIdx, 0), index(insertIdx, 0));
            } else {
                m_entries[existing].timestamp = entry.timestamp;
                emit dataChanged(index(existing, 0), index(existing, 0));
            }
            return;
        }

        const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
            if (entry.pinned && !e.pinned)
                return true;
            if (!entry.pinned && e.pinned)
                return false;
            return entry.timestamp >= e.timestamp;
        });

        const int  rawRow = static_cast<int>(std::distance(m_entries.begin(), insertPos));

        beginInsertRows({}, rawRow, rawRow);
        m_entries.insert(insertPos, entry);
        endInsertRows();

        emit countChanged();
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

    void ClipboardModel::setFilter(const QString& query, const QList<qint64>& orderedIds) {
        beginResetModel();
        m_filterQuery = query;
        m_filtering   = !query.isEmpty();
        m_filtered.clear();

        if (m_filtering) {
            for (qint64 id : orderedIds) {
                const int idx = indexById(id);
                if (idx >= 0)
                    m_filtered.append(idx);
            }
        } else {
            std::ranges::stable_sort(m_entries, [](const ClipboardEntry& a, const ClipboardEntry& b) {
                if (a.pinned != b.pinned)
                    return a.pinned > b.pinned;
                return a.timestamp > b.timestamp;
            });
        }

        endResetModel();
        emit countChanged();
    }

    void ClipboardModel::bumpToTop(qint64 id) {
        const int existing = indexById(id);
        if (existing < 0)
            return;

        m_entries[existing].timestamp = QDateTime::currentMSecsSinceEpoch();

        if (m_filtering) {
            beginResetModel();
            auto       item      = m_entries.takeAt(existing);
            const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
                if (item.pinned && !e.pinned)
                    return true;
                if (!item.pinned && e.pinned)
                    return false;
                return item.timestamp >= e.timestamp;
            });
            m_entries.insert(insertPos, std::move(item));
            rebuildFilter();
            endResetModel();
            emit countChanged();
            return;
        }

        const auto insertPos = std::ranges::find_if(m_entries, [&](const ClipboardEntry& e) {
            if (e.id == id)
                return false;
            auto const& item = m_entries[existing];
            if (item.pinned && !e.pinned)
                return true;
            if (!item.pinned && e.pinned)
                return false;
            return item.timestamp >= e.timestamp;
        });

        const int  dest = static_cast<int>(std::distance(m_entries.begin(), insertPos));
        if (existing != dest) {
            int destChild = dest > existing ? dest + 1 : dest;
            beginMoveRows({}, existing, existing, {}, destChild);
            auto item = m_entries.takeAt(existing);

            int  insertIdx = dest > existing ? dest - 1 : dest;
            m_entries.insert(insertIdx, std::move(item));
            endMoveRows();
            emit dataChanged(index(insertIdx, 0), index(insertIdx, 0));
        } else {
            emit dataChanged(index(existing, 0), index(existing, 0));
        }
    }

    const QList<ClipboardEntry>& ClipboardModel::allEntries() const noexcept {
        return m_entries;
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
