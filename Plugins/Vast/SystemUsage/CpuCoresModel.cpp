#include "CpuCoresModel.hpp"

namespace vast {

    CpuCoresModel::CpuCoresModel(QObject* parent) : QAbstractListModel(parent) {}

    int CpuCoresModel::rowCount(const QModelIndex& parent) const {
        if (parent.isValid())
            return 0;
        return static_cast<int>(mCores.size());
    }

    QVariant CpuCoresModel::data(const QModelIndex& index, int role) const {
        if (!index.isValid() || index.row() < 0 || index.row() >= mCores.size()) {
            return {};
        }

        const auto& core = mCores.at(index.row());
        switch (role) {
            case CoreIdRole: return core.coreId;
            case FreqMHzRole: return core.freqMHz;
            case UsagePercentRole: return core.usagePercent;
            default: return {};
        }
    }

    QHash<int, QByteArray> CpuCoresModel::roleNames() const {
        return {
            {CoreIdRole, "coreId"},
            {FreqMHzRole, "freqMHz"},
            {UsagePercentRole, "usagePercent"},
        };
    }

    QVariantMap CpuCoresModel::get(int row) const {
        if (row < 0 || row >= mCores.size())
            return {};
        const auto& core = mCores.at(row);
        return {
            {QStringLiteral("coreId"), core.coreId},
            {QStringLiteral("freqMHz"), core.freqMHz},
            {QStringLiteral("usagePercent"), core.usagePercent},
        };
    }

    void CpuCoresModel::updateCores(std::span<const CpuCoreEntry> cores) {
        if (mCores.size() != static_cast<qsizetype>(cores.size())) {
            beginResetModel();
            mCores.assign(cores.begin(), cores.end());
            endResetModel();
            emit countChanged();
            return;
        }

        for (qsizetype index = 0; index < mCores.size(); ++index) {
            if (mCores.at(index) != cores[static_cast<size_t>(index)]) {
                mCores[index]         = cores[static_cast<size_t>(index)];
                const auto modelIndex = createIndex(static_cast<int>(index), 0);
                emit       dataChanged(modelIndex, modelIndex);
            }
        }
    }

} // namespace vast
