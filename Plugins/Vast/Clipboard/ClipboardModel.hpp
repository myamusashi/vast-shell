#pragma once

#include "ClipboardEntry.hpp"

#include <QAbstractListModel>
#include <cstdint>
#include <qhash.h>
#include <qlist.h>
#include <QtQmlIntegration/qqmlintegration.h>

#include <qtmetamacros.h>
#include <qtclasshelpermacros.h>
#include <qnamespace.h>
#include <qtypes.h>
#include <vector>

namespace vast {

    class ClipboardModel : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via ClipboardManager.model")
        Q_DISABLE_COPY(ClipboardModel)

        Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
        Q_PROPERTY(TypeFilter typeFilter READ typeFilter WRITE setTypeFilter NOTIFY typeFilterChanged)

      public:
        enum class Roles : uint16_t {
            IdRole = Qt::UserRole,
            TypeRole,
            PreviewRole,
            TimestampRole,
            PinnedRole,
            SourceAppRole,
            MimeTypeRole,
            SizeBytesRole,
            FileNameRole,
        };
        Q_ENUM(Roles)

        enum class TypeFilter : uint8_t {
            All = 0,
            Text,
            Html,
            LinksAndFiles,
            Image,
        };
        Q_ENUM(TypeFilter)

        explicit ClipboardModel(QObject* parent = nullptr);
        ~ClipboardModel() override                                             = default;
        ClipboardModel(ClipboardModel&&)                                       = delete;
        ClipboardModel&                            operator=(ClipboardModel&&) = delete;

        [[nodiscard]] int                          rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant                     data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray>       roleNames() const override;
        [[nodiscard]] const QList<ClipboardEntry>& allEntries() const noexcept;

        [[nodiscard]] bool                         contains(qint64 id) const;
        void                                       reset(QList<ClipboardEntry> entries);
        void                                       prepend(const ClipboardEntry& entry);
        void                                       removeById(qint64 id);
        Q_INVOKABLE void                           removeByIds(const QVariantList& ids);
        void                                       setPinById(qint64 id, bool pinned);
        Q_INVOKABLE void                           setFilter(const QString& query);
        [[nodiscard]] TypeFilter                   typeFilter() const noexcept;
        Q_INVOKABLE void                           setTypeFilter(TypeFilter filter);
        Q_INVOKABLE void                           cycleTypeFilter();
        Q_INVOKABLE void                           resetTypeFilter();
        Q_INVOKABLE void                           clearSearchIndex();

        void                                       bumpToTop(qint64 id);

        [[nodiscard]] Q_INVOKABLE qint64           idAtRow(int row) const;
        [[nodiscard]] Q_INVOKABLE QVariantList     entries() const;
        [[nodiscard]] Q_INVOKABLE QString          typeAtRow(int row) const;

      Q_SIGNALS:
        void countChanged();
        void typeFilterChanged();

      private:
        [[nodiscard]] static QString        makePreview(const ClipboardEntry& e);
        [[nodiscard]] static bool           isUrlOrLink(const QString& content);
        [[nodiscard]] bool                  matchesTypeFilter(const ClipboardEntry& e) const;
        static void                         ensureSearchIndex(ClipboardEntry& e);
        [[nodiscard]] int                   indexById(qint64 id) const;

        void                                rebuildFilter();

        [[nodiscard]] const ClipboardEntry& visibleAt(int row) const;
        [[nodiscard]] int                   visibleCount() const;

        QList<ClipboardEntry>               mEntries;
        std::vector<int>                    mFiltered;
        QString                             mFilterQuery;
        TypeFilter                          mTypeFilter{TypeFilter::All};
        bool                                mFiltering{false};
    };
}
