#pragma once

#include "SystemStatParsers.hpp"

#include <qabstractitemmodel.h>
#include <qbytearray.h>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qlist.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include <span>

namespace vast {

    class FilesystemsModel final : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via SystemUsageMonitor.filesystems")

        Q_PROPERTY(qsizetype count READ count NOTIFY countChanged)

      public:
        enum Roles : uint16_t {
            DeviceNameRole = Qt::UserRole + 1,
            FilesystemTypeRole,
            MountPointRole,
            UsedKiBRole,
            FreeKiBRole,
            TotalKiBRole,
            UsedPercentRole,
            FormattedTotalRole,
            FormattedUsedRole,
            FormattedFreeRole,
        };
        Q_ENUM(Roles)

        explicit FilesystemsModel(QObject* parent = nullptr);
        ~FilesystemsModel() override                                       = default;
        FilesystemsModel(const FilesystemsModel&)                          = delete;
        FilesystemsModel& operator=(const FilesystemsModel&)               = delete;
        FilesystemsModel(FilesystemsModel&&)                               = delete;
        FilesystemsModel&                    operator=(FilesystemsModel&&) = delete;

        [[nodiscard]] int                    rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

        [[nodiscard]] qsizetype              count() const noexcept {
            return mFilesystems.size();
        }

        [[nodiscard]] Q_INVOKABLE QVariantMap get(int row) const;

        void                                  updateFilesystems(std::span<const sysusage::FilesystemEntry> filesystems);

      signals:
        void countChanged();

      private:
        QList<sysusage::FilesystemEntry> mFilesystems;
    };

} // namespace vast
