#pragma once

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

    struct CpuCoreEntry {
        int  coreId{0};
        int  freqMHz{0};
        int  usagePercent{0};
        auto operator<=>(const CpuCoreEntry&) const noexcept = default;
    };

    class CpuCoresModel final : public QAbstractListModel {
        Q_OBJECT
        QML_NAMED_ELEMENT(CpuCoresModel)
        QML_UNCREATABLE("Access via SystemUsageMonitor.cpuCores")

        Q_PROPERTY(qsizetype count READ count NOTIFY countChanged)

      public:
        enum Roles : uint16_t {
            CoreIdRole = Qt::UserRole + 1,
            FreqMHzRole,
            UsagePercentRole,
        };
        Q_ENUM(Roles)

        explicit CpuCoresModel(QObject* parent = nullptr);
        ~CpuCoresModel() override                                       = default;
        CpuCoresModel(const CpuCoresModel&)                             = delete;
        CpuCoresModel& operator=(const CpuCoresModel&)                  = delete;
        CpuCoresModel(CpuCoresModel&&)                                  = delete;
        CpuCoresModel&                       operator=(CpuCoresModel&&) = delete;

        [[nodiscard]] int                    rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

        [[nodiscard]] qsizetype              count() const noexcept {
            return mCores.size();
        }

        [[nodiscard]] Q_INVOKABLE QVariantMap get(int row) const;

        void                                  updateCores(std::span<const CpuCoreEntry> cores);

      Q_SIGNALS:
        void countChanged();

      private:
        QList<CpuCoreEntry> mCores;
    };

} // namespace vast
