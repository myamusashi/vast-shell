#pragma once

#include <qlist.h>
#include <qstring.h>

#include <optional>

namespace vast {

    struct SensorCoreInfo {
        int     coreId{0};
        QString frequencyPath;
    };

    class SensorScanner {
      public:
        explicit SensorScanner(QString sysRoot = QStringLiteral("/sys"));

        void                                       scan();

        [[nodiscard]] std::optional<double>        readCpuTemperature() const;
        [[nodiscard]] std::optional<double>        readGpuTemperature() const;
        [[nodiscard]] std::optional<double>        readBatteryTemperature() const;
        [[nodiscard]] QString                      readBatteryTechnology() const;

        [[nodiscard]] const QList<SensorCoreInfo>& coreFrequencyPaths() const noexcept {
            return mCoreFrequencyPaths;
        }

        void                  updateInterfaces(const QList<QString>& names);
        [[nodiscard]] QString detectWirelessInterface();
        [[nodiscard]] QString detectVpnStatus();

      private:
        struct TemperatureSource {
            QString path;
            double  divisor{1000.0};
        };

        QString               mSysRoot;
        TemperatureSource     mCpuTemperatureSource;
        TemperatureSource     mGpuTemperatureSource;
        TemperatureSource     mBatteryTemperatureSource;
        QString               mBatteryTechPath;
        QList<SensorCoreInfo> mCoreFrequencyPaths;

        QList<QString>        mInterfaceNames;
        QList<QString>        mVpnCandidates;
        QString               mCachedWirelessInterface;
        bool                  mWirelessScanned{false};

        void                  scanHwmonSensors();
        void                  scanBatterySensors();
        void                  scanCpuFreqPaths();
        void                  refreshVpnCandidates();
        [[nodiscard]] QString scanWirelessInterface() const;
    };

} // namespace vast
