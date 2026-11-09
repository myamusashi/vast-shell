#pragma once

#include "CpuCoresModel.hpp"
#include "FilesystemsModel.hpp"
#include "GraphicsInfoProbe.hpp"
#include "SensorScanner.hpp"
#include "SystemFormatters.hpp"
#include "SystemStatParsers.hpp"
#include "WirelessBitrateReader.hpp"

#include <qcontainerfwd.h>
#include <qelapsedtimer.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <cmath>

class tst_SystemUsage;

namespace vast {

    class SystemUsageMonitor final : public QObject {
        Q_OBJECT
        QML_NAMED_ELEMENT(SystemUsageMonitor)
        QML_SINGLETON

        Q_PROPERTY(bool running READ isRunning WRITE setRunning NOTIFY runningChanged)

        // System / Hardware Info
        Q_PROPERTY(QString archDesign READ archDesign CONSTANT)
        Q_PROPERTY(QString kernelName READ kernelName CONSTANT)
        Q_PROPERTY(QString osId READ osId CONSTANT)
        Q_PROPERTY(QString osIdLike READ osIdLike CONSTANT)
        Q_PROPERTY(QString osPrettyName READ osPrettyName CONSTANT)
        Q_PROPERTY(QString cpuName READ cpuName CONSTANT)
        Q_PROPERTY(QString gpuName READ gpuName NOTIFY gpuNameChanged)
        Q_PROPERTY(QString batteryTechnologies READ batteryTechnologies NOTIFY batteryTechnologiesChanged)

        // Temperatures & Battery
        Q_PROPERTY(double batteryTemp READ batteryTemp NOTIFY batteryTempChanged)
        Q_PROPERTY(double cpuTemp READ cpuTemp NOTIFY cpuTempChanged)
        Q_PROPERTY(double gpuTemp READ gpuTemp NOTIFY gpuTempChanged)

        // CPU & Memory
        Q_PROPERTY(int cpuPerc READ cpuPerc NOTIFY cpuPercChanged)
        Q_PROPERTY(vast::CpuCoresModel* cpuCores READ cpuCores CONSTANT)
        Q_PROPERTY(quint64 memTotal READ memTotal NOTIFY memTotalChanged)
        Q_PROPERTY(quint64 memUsed READ memUsed NOTIFY memUsedChanged)
        Q_PROPERTY(double memUsedGiB READ memUsedGiB NOTIFY memUsedGiBChanged)

        // Storage & Filesystems
        Q_PROPERTY(quint64 diskTotal READ diskTotal NOTIFY diskTotalChanged)
        Q_PROPERTY(quint64 diskUsed READ diskUsed NOTIFY diskUsedChanged)
        Q_PROPERTY(double diskUsedGiB READ diskUsedGiB NOTIFY diskUsedGiBChanged)
        Q_PROPERTY(double diskPercent READ diskPercent NOTIFY diskPercentChanged)
        Q_PROPERTY(quint64 storageAppsData READ storageAppsData NOTIFY storageAppsDataChanged)
        Q_PROPERTY(quint64 storageSystem READ storageSystem NOTIFY storageSystemChanged)
        Q_PROPERTY(quint64 storageFree READ storageFree NOTIFY storageFreeChanged)
        Q_PROPERTY(vast::FilesystemsModel* filesystems READ filesystems CONSTANT)

        // Uptime
        Q_PROPERTY(QString uptimeFormatted READ uptimeFormatted NOTIFY uptimeFormattedChanged)

        // Network
        Q_PROPERTY(QString wiredInterface READ wiredInterface WRITE setWiredInterface NOTIFY wiredInterfaceChanged)
        Q_PROPERTY(QString wirelessInterface READ wirelessInterface NOTIFY wirelessInterfaceChanged)
        Q_PROPERTY(int wirelessLinkSpeed READ wirelessLinkSpeed NOTIFY wirelessLinkSpeedChanged)
        Q_PROPERTY(QString statusVPNInterface READ statusVPNInterface NOTIFY statusVPNInterfaceChanged)
        Q_PROPERTY(double wiredDownloadSpeed READ wiredDownloadSpeed NOTIFY wiredDownloadSpeedChanged)
        Q_PROPERTY(double wiredUploadSpeed READ wiredUploadSpeed NOTIFY wiredUploadSpeedChanged)
        Q_PROPERTY(double wirelessDownloadSpeed READ wirelessDownloadSpeed NOTIFY wirelessDownloadSpeedChanged)
        Q_PROPERTY(double wirelessUploadSpeed READ wirelessUploadSpeed NOTIFY wirelessUploadSpeedChanged)
        Q_PROPERTY(double totalWiredDownloadUsage READ totalWiredDownloadUsage NOTIFY totalWiredDownloadUsageChanged)
        Q_PROPERTY(double totalWiredUploadUsage READ totalWiredUploadUsage NOTIFY totalWiredUploadUsageChanged)
        Q_PROPERTY(double totalWirelessDownloadUsage READ totalWirelessDownloadUsage NOTIFY totalWirelessDownloadUsageChanged)
        Q_PROPERTY(double totalWirelessUploadUsage READ totalWirelessUploadUsage NOTIFY totalWirelessUploadUsageChanged)

        // Graphics API
        Q_PROPERTY(bool vulkanAvailable READ vulkanAvailable NOTIFY graphicsInfoChanged)
        Q_PROPERTY(QString vulkanVersion READ vulkanVersion NOTIFY graphicsInfoChanged)
        Q_PROPERTY(bool openglAvailable READ openglAvailable NOTIFY graphicsInfoChanged)
        Q_PROPERTY(QString openglVersion READ openglVersion NOTIFY graphicsInfoChanged)
        Q_PROPERTY(QString openglVendor READ openglVendor NOTIFY graphicsInfoChanged)
        Q_PROPERTY(QString openglRenderer READ openglRenderer NOTIFY graphicsInfoChanged)
        Q_PROPERTY(QString vaApiDriver READ vaApiDriver NOTIFY graphicsInfoChanged)

      public:
        explicit SystemUsageMonitor(QObject* parent = nullptr, QString procNetDevPath = QStringLiteral("/proc/net/dev"), QString lspciProgram = QStringLiteral("lspci"),
                                    QString sysRoot = QStringLiteral("/sys"));
        ~SystemUsageMonitor() override                           = default;
        SystemUsageMonitor(const SystemUsageMonitor&)            = delete;
        SystemUsageMonitor& operator=(const SystemUsageMonitor&) = delete;
        SystemUsageMonitor(SystemUsageMonitor&&)                 = delete;
        SystemUsageMonitor& operator=(SystemUsageMonitor&&)      = delete;
        [[nodiscard]] bool  isRunning() const noexcept {
            return mRunning;
        }
        void                         setRunning(bool running);

        [[nodiscard]] const QString& archDesign() const noexcept {
            return mArchDesign;
        }
        [[nodiscard]] const QString& kernelName() const noexcept {
            return mKernelName;
        }
        [[nodiscard]] const QString& osId() const noexcept {
            return mOsId;
        }
        [[nodiscard]] const QString& osIdLike() const noexcept {
            return mOsIdLike;
        }
        [[nodiscard]] const QString& osPrettyName() const noexcept {
            return mOsPrettyName;
        }
        [[nodiscard]] const QString& cpuName() const noexcept {
            return mCpuName;
        }
        [[nodiscard]] const QString& gpuName() const noexcept {
            return mGpuName;
        }
        [[nodiscard]] const QString& batteryTechnologies() const noexcept {
            return mBatteryTechnologies;
        }

        [[nodiscard]] double batteryTemp() const noexcept {
            return mBatteryTemp;
        }
        [[nodiscard]] double cpuTemp() const noexcept {
            return mCpuTemp;
        }
        [[nodiscard]] double gpuTemp() const noexcept {
            return mGpuTemp;
        }

        [[nodiscard]] int cpuPerc() const noexcept {
            return mCpuPerc;
        }
        [[nodiscard]] CpuCoresModel* cpuCores() const noexcept {
            return mCpuCoresModel;
        }
        [[nodiscard]] quint64 memTotal() const noexcept {
            return mMemTotal;
        }
        [[nodiscard]] quint64 memUsed() const noexcept {
            return mMemUsed;
        }
        [[nodiscard]] double memUsedGiB() const noexcept {
            return mMemUsedGiB;
        }

        [[nodiscard]] quint64 diskTotal() const noexcept {
            return mDiskTotal;
        }
        [[nodiscard]] quint64 diskUsed() const noexcept {
            return mDiskUsed;
        }
        [[nodiscard]] double diskUsedGiB() const noexcept {
            return mDiskUsedGiB;
        }
        [[nodiscard]] double diskPercent() const noexcept {
            return mDiskPercent;
        }
        [[nodiscard]] quint64 storageAppsData() const noexcept {
            return mStorageAppsData;
        }
        [[nodiscard]] quint64 storageSystem() const noexcept {
            return mStorageSystem;
        }
        [[nodiscard]] quint64 storageFree() const noexcept {
            return mStorageFree;
        }
        [[nodiscard]] FilesystemsModel* filesystems() const noexcept {
            return mFilesystemsModel;
        }

        [[nodiscard]] const QString& uptimeFormatted() const noexcept {
            return mUptimeFormatted;
        }

        [[nodiscard]] const QString& wiredInterface() const noexcept {
            return mWiredInterface;
        }
        void                         setWiredInterface(const QString& iface);

        [[nodiscard]] const QString& wirelessInterface() const noexcept {
            return mWirelessInterface;
        }
        [[nodiscard]] int wirelessLinkSpeed() const noexcept {
            return mWirelessLinkSpeed;
        }
        [[nodiscard]] const QString& statusVPNInterface() const noexcept {
            return mStatusVPNInterface;
        }
        [[nodiscard]] double wiredDownloadSpeed() const noexcept {
            return mWiredDownloadSpeed;
        }
        [[nodiscard]] double wiredUploadSpeed() const noexcept {
            return mWiredUploadSpeed;
        }
        [[nodiscard]] double wirelessDownloadSpeed() const noexcept {
            return mWirelessDownloadSpeed;
        }
        [[nodiscard]] double wirelessUploadSpeed() const noexcept {
            return mWirelessUploadSpeed;
        }
        [[nodiscard]] double totalWiredDownloadUsage() const noexcept {
            return mTotalWiredDownloadUsage;
        }
        [[nodiscard]] double totalWiredUploadUsage() const noexcept {
            return mTotalWiredUploadUsage;
        }
        [[nodiscard]] double totalWirelessDownloadUsage() const noexcept {
            return mTotalWirelessDownloadUsage;
        }
        [[nodiscard]] double totalWirelessUploadUsage() const noexcept {
            return mTotalWirelessUploadUsage;
        }

        [[nodiscard]] bool vulkanAvailable() const noexcept {
            return mGraphicsSummary.vulkanAvailable;
        }
        [[nodiscard]] const QString& vulkanVersion() const noexcept {
            return mGraphicsSummary.vulkanVersion;
        }
        [[nodiscard]] bool openglAvailable() const noexcept {
            return mGraphicsSummary.openglAvailable;
        }
        [[nodiscard]] const QString& openglVersion() const noexcept {
            return mGraphicsSummary.openglVersion;
        }
        [[nodiscard]] const QString& openglVendor() const noexcept {
            return mGraphicsSummary.openglVendor;
        }
        [[nodiscard]] const QString& openglRenderer() const noexcept {
            return mGraphicsSummary.openglRenderer;
        }
        [[nodiscard]] const QString& vaApiDriver() const noexcept {
            return mGraphicsSummary.vaApiDriver;
        }

        [[nodiscard]] Q_INVOKABLE static QString formatKiB(double kib) {
            return sysusage::formatKiB(kib < 0.0 ? 0ULL : static_cast<quint64>(std::llround(kib)));
        }
        [[nodiscard]] Q_INVOKABLE static QString formatUsageMiB(double usageMiB) {
            return sysusage::formatUsageMiB(usageMiB);
        }
        [[nodiscard]] Q_INVOKABLE static QString formatSpeedMiBps(double speedMiBps) {
            return sysusage::formatSpeedMiBps(speedMiBps);
        }
        Q_INVOKABLE void ensureGraphicsInfoLoaded();
        Q_INVOKABLE void sampleNow();

      Q_SIGNALS:
        void runningChanged();
        void gpuNameChanged();
        void batteryTechnologiesChanged();
        void batteryTempChanged();
        void cpuTempChanged();
        void gpuTempChanged();
        void cpuPercChanged();
        void memTotalChanged();
        void memUsedChanged();
        void memUsedGiBChanged();
        void diskTotalChanged();
        void diskUsedChanged();
        void diskUsedGiBChanged();
        void diskPercentChanged();
        void storageAppsDataChanged();
        void storageSystemChanged();
        void storageFreeChanged();
        void uptimeFormattedChanged();
        void wiredInterfaceChanged();
        void wirelessInterfaceChanged();
        void wirelessLinkSpeedChanged();
        void statusVPNInterfaceChanged();
        void wiredDownloadSpeedChanged();
        void wiredUploadSpeedChanged();
        void wirelessDownloadSpeedChanged();
        void wirelessUploadSpeedChanged();
        void totalWiredDownloadUsageChanged();
        void totalWiredUploadUsageChanged();
        void totalWirelessDownloadUsageChanged();
        void totalWirelessUploadUsageChanged();
        void graphicsInfoChanged();

      private:
        bool          mRunning{false};
        QTimer*       mTimer{nullptr};
        QElapsedTimer mLastStorageSample;
        QElapsedTimer mLastWirelessSample;
        bool          mStorageCollectionInFlight{false};
        QElapsedTimer mLastSampleTime;

        // Static info
        QString mArchDesign;
        QString mKernelName;
        QString mOsId;
        QString mOsIdLike;
        QString mOsPrettyName;
        QString mCpuName;
        QString mGpuName;
        QString mBatteryTechnologies;

        // State snapshots
        sysusage::CpuStatSnapshot                      mPreviousCpuStat;
        QHash<QString, sysusage::NetInterfaceCounters> mPreviousNetCounters;
        QHash<int, QString>                            mFrequencyPathByCoreId;
        SensorScanner                                  mSensorScanner;
        // Owned via Qt parent-child. Not exposed to QML directly; results arrive via bitrateResolved.
        WirelessBitrateReader*    mWirelessReader{nullptr};
        GraphicsInfoProbe*        mGraphicsProbe{nullptr};
        sysusage::GraphicsSummary mGraphicsSummary;

        // Models
        CpuCoresModel*    mCpuCoresModel{nullptr};
        FilesystemsModel* mFilesystemsModel{nullptr};

        // Cached dynamic values
        double  mBatteryTemp{0.0};
        double  mCpuTemp{0.0};
        double  mGpuTemp{0.0};
        int     mCpuPerc{0};
        quint64 mMemTotal{0};
        quint64 mMemUsed{0};
        double  mMemUsedGiB{0.0};
        quint64 mDiskTotal{0};
        quint64 mDiskUsed{0};
        double  mDiskUsedGiB{0.0};
        double  mDiskPercent{0.0};
        quint64 mStorageAppsData{0};
        quint64 mStorageSystem{0};
        quint64 mStorageFree{0};
        QString mUptimeFormatted;

        QString mWiredInterface;
        QString mWirelessInterface;
        int     mWirelessLinkSpeed{0};
        QString mStatusVPNInterface{QStringLiteral("disconnected")};
        double  mWiredDownloadSpeed{0.0};
        double  mWiredUploadSpeed{0.0};
        double  mWirelessDownloadSpeed{0.0};
        double  mWirelessUploadSpeed{0.0};
        double  mTotalWiredDownloadUsage{0.0};
        double  mTotalWiredUploadUsage{0.0};
        double  mTotalWirelessDownloadUsage{0.0};
        double  mTotalWirelessUploadUsage{0.0};

        QString mProcNetDevPath;
        QString mLspciProgram;

        void    initializeStaticInfo();
        void    detectGpuNameFromLspciAsync();
        void    applyGpuName(const QString& name);
        void    sampleCpu();
        void    sampleMemory();
        void    sampleUptime();
        void    updateTemperature(std::optional<double> reading, double& cachedValue, void (SystemUsageMonitor::*changedSignal)());
        void    sampleSensors();
        void    sampleNetwork(double elapsedSeconds);
        void    resetWiredState();
        void    resetWirelessState();
        void    sampleStorageAsync();
        void    applyStorageSummary(const sysusage::StorageSummary& summary);

        friend class ::tst_SystemUsage;
    };

} // namespace vast
