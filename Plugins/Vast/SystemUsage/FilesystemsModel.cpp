#include "FilesystemsModel.hpp"
#include "SystemFormatters.hpp"

namespace vast {

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
        if (mFilesystems.size() != static_cast<qsizetype>(filesystems.size())) {
            beginResetModel();
            mFilesystems.assign(filesystems.begin(), filesystems.end());
            endResetModel();
            emit countChanged();
            return;
        }

        for (qsizetype index = 0; index < mFilesystems.size(); ++index) {
            if (mFilesystems.at(index) != filesystems[static_cast<size_t>(index)]) {
                mFilesystems[index]   = filesystems[static_cast<size_t>(index)];
                const auto modelIndex = createIndex(static_cast<int>(index), 0);
                emit       dataChanged(modelIndex, modelIndex);
            }
        }
    }

} // namespace vast
