#include "FilesystemsModel.hpp"
#include "ModelDiffHelper.hpp"
#include "SystemFormatters.hpp"

#include <algorithm>

namespace vast {

    namespace {

        const QList<int> CHANGED_FILESYSTEM_ROLES{
            FilesystemsModel::DeviceNameRole,    FilesystemsModel::FilesystemTypeRole, FilesystemsModel::MountPointRole,  FilesystemsModel::UsedKiBRole,
            FilesystemsModel::FreeKiBRole,       FilesystemsModel::TotalKiBRole,       FilesystemsModel::UsedPercentRole, FilesystemsModel::FormattedTotalRole,
            FilesystemsModel::FormattedUsedRole, FilesystemsModel::FormattedFreeRole,
        };

    } // namespace

    FilesystemsModel::FilesystemsModel(QObject* parent) : QAbstractListModel(parent) {}

    int FilesystemsModel::rowCount(const QModelIndex& parent) const {
        if (parent.isValid())
            return 0;
        return static_cast<int>(mFilesystems.size());
    }

    QVariant FilesystemsModel::data(const QModelIndex& index, int role) const {
        if (!index.isValid() || index.row() < 0 || index.row() >= mFilesystems.size()) {
            return {};
        }

        const auto& entry = mFilesystems.at(index.row());
        switch (role) {
            case DeviceNameRole: return entry.deviceName;
            case FilesystemTypeRole: return entry.filesystemType;
            case MountPointRole: return entry.mountPoint;
            case UsedKiBRole: return entry.usedKiB;
            case FreeKiBRole: return entry.freeKiB;
            case TotalKiBRole: return entry.totalKiB;
            case UsedPercentRole: return entry.usedPercent;
            case FormattedTotalRole: return sysusage::formatKiB(entry.totalKiB);
            case FormattedUsedRole: return sysusage::formatKiB(entry.usedKiB);
            case FormattedFreeRole: return sysusage::formatKiB(entry.freeKiB);
            default: return {};
        }
    }

    QHash<int, QByteArray> FilesystemsModel::roleNames() const {
        return {
            {DeviceNameRole, "deviceName"},
            {FilesystemTypeRole, "filesystemType"},
            {MountPointRole, "mountPoint"},
            {UsedKiBRole, "usedKiB"},
            {FreeKiBRole, "freeKiB"},
            {TotalKiBRole, "totalKiB"},
            {UsedPercentRole, "usedPercent"},
            {FormattedTotalRole, "formattedTotal"},
            {FormattedUsedRole, "formattedUsed"},
            {FormattedFreeRole, "formattedFree"},
        };
    }

    QVariantMap FilesystemsModel::get(int row) const {
        if (row < 0 || row >= mFilesystems.size())
            return {};
        const auto& entry = mFilesystems.at(row);
        return {
            {QStringLiteral("deviceName"), entry.deviceName},
            {QStringLiteral("filesystemType"), entry.filesystemType},
            {QStringLiteral("mountPoint"), entry.mountPoint},
            {QStringLiteral("usedKiB"), entry.usedKiB},
            {QStringLiteral("freeKiB"), entry.freeKiB},
            {QStringLiteral("totalKiB"), entry.totalKiB},
            {QStringLiteral("usedPercent"), entry.usedPercent},
            {QStringLiteral("formattedTotal"), sysusage::formatKiB(entry.totalKiB)},
            {QStringLiteral("formattedUsed"), sysusage::formatKiB(entry.usedKiB)},
            {QStringLiteral("formattedFree"), sysusage::formatKiB(entry.freeKiB)},
        };
    }

    void FilesystemsModel::updateFilesystems(std::span<const sysusage::FilesystemEntry> filesystems) {
        const bool sizeChanged = mFilesystems.size() != static_cast<qsizetype>(filesystems.size());
        const bool devicesChanged =
            !sizeChanged && !std::ranges::equal(mFilesystems, filesystems, {}, &sysusage::FilesystemEntry::deviceName, &sysusage::FilesystemEntry::deviceName);

        if (sizeChanged || devicesChanged) {
            beginResetModel();
            mFilesystems.assign(filesystems.begin(), filesystems.end());
            endResetModel();
            Q_EMIT countChanged();
            return;
        }

        updateChangedRows(mFilesystems, filesystems, [this](int row) {
            const auto modelIndex = index(row);
            Q_EMIT dataChanged(modelIndex, modelIndex, CHANGED_FILESYSTEM_ROLES);
        });
    }

} // namespace vast
