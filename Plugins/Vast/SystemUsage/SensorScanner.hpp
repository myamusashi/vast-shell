#pragma once

#include <qcontainerfwd.h>
#include <qlist.h>
#include <qpair.h>
#include <qstring.h>

#include <optional>

namespace vast {

    class SensorScanner {
      public:
        explicit SensorScanner(const QString& sysRoot = QStringLiteral("/sys"));

        void                                            scan();

        [[nodiscard]] double                            readCpuTemperature() const;
        [[nodiscard]] double                            readGpuTemperature() const;
        [[nodiscard]] double                            readBatteryTemperature() const;
        [[nodiscard]] QString                           readBatteryTechnology() const;

        [[nodiscard]] const QList<QPair<int, QString>>& coreFrequencyPaths() const noexcept {
            return mCoreFrequencyPaths;
        }

        [[nodiscard]] QString detectWirelessInterface() const;
        [[nodiscard]] QString detectVpnStatus() const;

      private:
        QString                    mSysRoot;
        QString                    mCpuTempPath;
        QString                    mGpuTempPath;
        QString                    mBatteryTempPath;
        QString                    mBatteryTechPath;
        QList<QPair<int, QString>> mCoreFrequencyPaths;

        void                       scanHwmonSensors();
        void                       scanBatterySensors();
        void                       scanCpuFreqPaths();
    };

} // namespace vast
