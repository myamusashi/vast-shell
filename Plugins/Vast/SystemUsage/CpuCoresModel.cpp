#include "CpuCoresModel.hpp"
#include "ModelDiffHelper.hpp"

namespace vast {

    namespace {

        const QList<int> CHANGED_CPU_CORE_ROLES{CpuCoresModel::CoreIdRole, CpuCoresModel::FreqMHzRole, CpuCoresModel::UsagePercentRole};

    } // namespace

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

        updateChangedRows(mCores, cores, [this](int row) {
            const auto modelIndex = index(row);
            emit       dataChanged(modelIndex, modelIndex, CHANGED_CPU_CORE_ROLES);
        });
    }

} // namespace vast
