#include "SystemUsageMonitor.hpp"
#include "../Jobs/JobExecutor.hpp"
#include "StorageCollector.hpp"

#include <qcoreapplication.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qpointer.h>
#include <qprocess.h>
#include <qstringview.h>

#include <sys/utsname.h>
#include <algorithm>
#include <cmath>

namespace vast {

    namespace {
        constexpr qint64         STORAGE_SAMPLE_INTERVAL_MILLISECONDS  = 8000;
        constexpr qint64         WIRELESS_SAMPLE_INTERVAL_MILLISECONDS = 8000;

        [[nodiscard]] QByteArray readFileTrimmed(const QString& path) {
            QFile file(path);
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                return {};
            return file.readAll().trimmed();
        }

        [[nodiscard]] QString detectGpuNameFromSysfs() {
            const QDir drmDir(QStringLiteral("/sys/class/drm"));
            const auto cards = drmDir.entryList(QStringList{QStringLiteral("card[0-9]*")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

            for (const auto& card : cards) {
                if (card.contains(u'-'))
                    continue;

                const QString    ueventPath    = drmDir.absoluteFilePath(card) + QStringLiteral("/device/uevent");
                const QByteArray ueventContent = readFileTrimmed(ueventPath);
                if (ueventContent.isEmpty())
                    continue;

                const QString                text  = QString::fromUtf8(ueventContent.data(), ueventContent.size());
                const auto                   lines = QStringView(text).split(u'\n');

                static constexpr QStringView pciSlotPrefix = u"PCI_SLOT_NAME=";

                QString                      pciSlot;
                for (const auto& line : lines) {
                    if (line.startsWith(pciSlotPrefix)) {
                        pciSlot = line.mid(pciSlotPrefix.size()).trimmed().toString();
                        break;
                    }
                }

                if (!pciSlot.isEmpty()) {
                    const QString    udevDataPath = QStringLiteral("/run/udev/data/+pci:") + pciSlot;
                    const QByteArray udevData     = readFileTrimmed(udevDataPath);
                    if (!udevData.isEmpty()) {
                        const QString gpuName = sysusage::parseUdevPciGpuName(udevData);
                        if (!gpuName.isEmpty())
                            return gpuName;
                    }
                }
            }

            return {};
        }

    } // namespace

    SystemUsageMonitor::SystemUsageMonitor(QObject* parent, QString procNetDevPath, QString lspciProgram, QString sysRoot) :
        QObject(parent), mTimer(new QTimer(this)), mSensorScanner(std::move(sysRoot)), mWirelessReader(new WirelessBitrateReader(this)), mCpuCoresModel(new CpuCoresModel(this)),
        mFilesystemsModel(new FilesystemsModel(this)), mProcNetDevPath(std::move(procNetDevPath)), mLspciProgram(std::move(lspciProgram)) {
        initializeStaticInfo();

        connect(mWirelessReader, &WirelessBitrateReader::bitrateResolved, this, [this](const QString& interfaceName, int bitrateMbps) {
            if (interfaceName != mWirelessInterface)
                return;
            if (bitrateMbps != mWirelessLinkSpeed) {
                mWirelessLinkSpeed = bitrateMbps;
                Q_EMIT wirelessLinkSpeedChanged();
            }
        });

        mTimer->setInterval(2000);
        connect(mTimer, &QTimer::timeout, this, &SystemUsageMonitor::sampleNow);
    }

    void SystemUsageMonitor::detectGpuNameFromLspciAsync() {
        auto* process = new QProcess(this);
        auto* timeout = new QTimer(process);
        timeout->setSingleShot(true);
        timeout->setInterval(1000);
        connect(timeout, &QTimer::timeout, process, &QProcess::kill);

        connect(process, &QProcess::finished, this, [this, process](int exitCode, QProcess::ExitStatus exitStatus) {
            if (exitStatus == QProcess::NormalExit && exitCode == 0)
                applyGpuName(sysusage::parseLspciGpuName(process->readAllStandardOutput()));
            process->deleteLater();
        });
        connect(process, &QProcess::errorOccurred, this, [process](QProcess::ProcessError error) {
            if (error == QProcess::FailedToStart)
                process->deleteLater();
        });

        process->start(mLspciProgram, {});
        timeout->start();
    }

    void SystemUsageMonitor::applyGpuName(const QString& name) {
        if (!name.isEmpty() && name != mGpuName) {
            mGpuName = name;
            Q_EMIT gpuNameChanged();
        }
    }

    void SystemUsageMonitor::setRunning(bool running) {
        if (mRunning == running)
            return;

        mRunning = running;
        Q_EMIT runningChanged();

        if (mRunning) {
            mLastSampleTime.start();
            sampleNow();
            mTimer->start();
        } else {
            mTimer->stop();
            mPreviousCpuStat = sysusage::CpuStatSnapshot{};
            mPreviousNetCounters.clear();
        }
    }

    void SystemUsageMonitor::setWiredInterface(const QString& iface) {
        if (mWiredInterface == iface)
            return;
        mWiredInterface = iface;
        Q_EMIT wiredInterfaceChanged();
    }

    void SystemUsageMonitor::ensureGraphicsInfoLoaded() {
        if (!mGraphicsProbe) {
            mGraphicsProbe = new GraphicsInfoProbe(this);
            connect(mGraphicsProbe, &GraphicsInfoProbe::finished, this, [this](const sysusage::GraphicsSummary& summary) {
                mGraphicsSummary = summary;
                Q_EMIT graphicsInfoChanged();
            });
        }
        mGraphicsProbe->startProbe();
    }

    void SystemUsageMonitor::initializeStaticInfo() {
        // 1. Kernel name & Architecture from uname(2)
        struct utsname hostInfo{};
        if (uname(&hostInfo) == 0) {
            mKernelName = QString::fromUtf8(hostInfo.release);
            mArchDesign = QString::fromUtf8(hostInfo.machine);
        }

        // 2. OS Release info
        QByteArray osReleaseContent = readFileTrimmed(QStringLiteral("/etc/os-release"));
        if (osReleaseContent.isEmpty()) {
            osReleaseContent = readFileTrimmed(QStringLiteral("/usr/lib/os-release"));
        }
        if (!osReleaseContent.isEmpty()) {
            const auto osRelease = sysusage::parseOsRelease(osReleaseContent);
            mOsId                = osRelease.id;
            mOsIdLike            = osRelease.idLike;
            mOsPrettyName        = !osRelease.prettyName.isEmpty() ? osRelease.prettyName : osRelease.name;
        }

        // 3. CPU model name
        const QByteArray cpuinfoContent = readFileTrimmed(QStringLiteral("/proc/cpuinfo"));
        if (!cpuinfoContent.isEmpty()) {
            mCpuName = sysusage::parseCpuModelName(cpuinfoContent);
        }
        // 4. GPU model name
        mGpuName = detectGpuNameFromSysfs();

        // 5. Sensor scanner init
        mSensorScanner.scan();
        mBatteryTechnologies = mSensorScanner.readBatteryTechnology();
        for (const auto& coreInfo : mSensorScanner.coreFrequencyPaths())
            mFrequencyPathByCoreId.insert(coreInfo.coreId, coreInfo.frequencyPath);
        mWirelessInterface = mSensorScanner.detectWirelessInterface();

        // 6. lspci fallback is async; skip entirely when udev already resolved the name
        if (mGpuName.isEmpty())
            detectGpuNameFromLspciAsync();
    }

    void SystemUsageMonitor::sampleNow() {
        const double elapsedSeconds = mLastSampleTime.isValid() ? static_cast<double>(mLastSampleTime.restart()) / 1000.0 : 2.0;

        sampleCpu();
        sampleMemory();
        sampleUptime();
        sampleSensors();
        sampleNetwork(elapsedSeconds);

        if (!mLastStorageSample.isValid() || mLastStorageSample.elapsed() >= STORAGE_SAMPLE_INTERVAL_MILLISECONDS) {
            sampleStorageAsync();
            mLastStorageSample.restart();
        }
    }

    void SystemUsageMonitor::sampleCpu() {
        const QByteArray statContent = readFileTrimmed(QStringLiteral("/proc/stat"));
        if (statContent.isEmpty())
            return;

        const auto currentStat = sysusage::parseCpuStat(statContent);
        if (!currentStat.valid)
            return;

        if (mPreviousCpuStat.valid) {
            const int percent = sysusage::computeCpuUsagePercent(mPreviousCpuStat.aggregate, currentStat.aggregate);
            if (percent != mCpuPerc) {
                mCpuPerc = percent;
                Q_EMIT cpuPercChanged();
            }
        }

        // Sample per-core frequencies and usage; driven by /proc/stat so no-cpufreq systems still list cores
        QList<CpuCoreEntry> coreEntries;
        coreEntries.reserve(currentStat.perCore.size());

        for (auto coreIterator = currentStat.perCore.cbegin(); coreIterator != currentStat.perCore.cend(); ++coreIterator) {
            const int  coreId                = coreIterator.key();
            int        freqMHz               = 0;
            const auto frequencyPathIterator = mFrequencyPathByCoreId.constFind(coreId);
            if (frequencyPathIterator != mFrequencyPathByCoreId.constEnd()) {
                const QByteArray freqContent = readFileTrimmed(frequencyPathIterator.value());
                if (auto parsedFreq = sysusage::parseFrequencyMHz(freqContent)) {
                    freqMHz = *parsedFreq;
                }
            }

            int coreUsage = 0;
            if (mPreviousCpuStat.valid) {
                const auto previousIterator = mPreviousCpuStat.perCore.constFind(coreId);
                if (previousIterator != mPreviousCpuStat.perCore.constEnd()) {
                    coreUsage = sysusage::computeCpuUsagePercent(previousIterator.value(), coreIterator.value());
                }
            }

            coreEntries.append(CpuCoreEntry{
                .coreId       = coreId,
                .freqMHz      = freqMHz,
                .usagePercent = coreUsage,
            });
        }

        mCpuCoresModel->updateCores(coreEntries);
        mPreviousCpuStat = currentStat;
    }

    void SystemUsageMonitor::sampleMemory() {
        const QByteArray meminfoContent = readFileTrimmed(QStringLiteral("/proc/meminfo"));
        if (meminfoContent.isEmpty())
            return;

        const auto mem = sysusage::parseMemInfo(meminfoContent);
        if (!mem.valid)
            return;

        if (mem.totalKiB != mMemTotal) {
            mMemTotal = mem.totalKiB;
            Q_EMIT memTotalChanged();
        }
        if (mem.usedKiB != mMemUsed) {
            mMemUsed = mem.usedKiB;
            Q_EMIT memUsedChanged();

            const double usedGiB = static_cast<double>(mMemUsed) / 1048576.0;
            if (std::abs(usedGiB - mMemUsedGiB) >= 0.001) {
                mMemUsedGiB = usedGiB;
                Q_EMIT memUsedGiBChanged();
            }
        }
    }

    void SystemUsageMonitor::sampleUptime() {
        const QByteArray uptimeContent = readFileTrimmed(QStringLiteral("/proc/uptime"));
        if (uptimeContent.isEmpty())
            return;

        if (auto seconds = sysusage::parseUptimeSeconds(uptimeContent)) {
            const QString formatted = sysusage::formatUptime(*seconds);
            if (formatted != mUptimeFormatted) {
                mUptimeFormatted = formatted;
                Q_EMIT uptimeFormattedChanged();
            }
        }
    }

    void SystemUsageMonitor::updateTemperature(std::optional<double> reading, double& cachedValue, void (SystemUsageMonitor::*changedSignal)()) {
        if (reading) {
            if (std::abs(*reading - cachedValue) >= 0.1) {
                cachedValue = *reading;
                Q_EMIT(this->*changedSignal)();
            }
        } else if (cachedValue != 0.0) {
            cachedValue = 0.0;
            Q_EMIT(this->*changedSignal)();
        }
    }

    void SystemUsageMonitor::sampleSensors() {
        updateTemperature(mSensorScanner.readCpuTemperature(), mCpuTemp, &SystemUsageMonitor::cpuTempChanged);
        updateTemperature(mSensorScanner.readGpuTemperature(), mGpuTemp, &SystemUsageMonitor::gpuTempChanged);
        updateTemperature(mSensorScanner.readBatteryTemperature(), mBatteryTemp, &SystemUsageMonitor::batteryTempChanged);
    }

    void SystemUsageMonitor::resetWiredState() {
        if (mWiredDownloadSpeed > 0.0) {
            mWiredDownloadSpeed = 0.0;
            Q_EMIT wiredDownloadSpeedChanged();
        }
        if (mWiredUploadSpeed > 0.0) {
            mWiredUploadSpeed = 0.0;
            Q_EMIT wiredUploadSpeedChanged();
        }
    }

    void SystemUsageMonitor::resetWirelessState() {
        if (!mWirelessInterface.isEmpty()) {
            mWirelessInterface.clear();
            Q_EMIT wirelessInterfaceChanged();
        }
        if (mWirelessLinkSpeed != 0) {
            mWirelessLinkSpeed = 0;
            Q_EMIT wirelessLinkSpeedChanged();
        }
        if (mWirelessDownloadSpeed > 0.0) {
            mWirelessDownloadSpeed = 0.0;
            Q_EMIT wirelessDownloadSpeedChanged();
        }
        if (mWirelessUploadSpeed > 0.0) {
            mWirelessUploadSpeed = 0.0;
            Q_EMIT wirelessUploadSpeedChanged();
        }
    }

    void SystemUsageMonitor::sampleNetwork(double elapsedSeconds) {
        const QByteArray netdevContent = readFileTrimmed(mProcNetDevPath);
        if (netdevContent.isEmpty()) {
            mSensorScanner.updateInterfaces({});
            resetWiredState();
            resetWirelessState();
            if (mStatusVPNInterface != QStringLiteral("disconnected")) {
                mStatusVPNInterface = QStringLiteral("disconnected");
                Q_EMIT statusVPNInterfaceChanged();
            }
            mPreviousNetCounters.clear();
            return;
        }

        const auto currentCounters = sysusage::parseNetDev(netdevContent);
        mSensorScanner.updateInterfaces(currentCounters.keys());

        if (!mWirelessInterface.isEmpty() && !currentCounters.contains(mWirelessInterface)) {
            resetWirelessState();
        }

        if (mWirelessInterface.isEmpty()) {
            const QString wireless = mSensorScanner.detectWirelessInterface();
            if (!wireless.isEmpty()) {
                mWirelessInterface = wireless;
                Q_EMIT wirelessInterfaceChanged();
            }
        }

        // Process wired interface metrics
        if (!mWiredInterface.isEmpty() && currentCounters.contains(mWiredInterface)) {
            const auto   current   = currentCounters.value(mWiredInterface);
            const double totalDown = static_cast<double>(current.rxBytes) / 1048576.0;
            const double totalUp   = static_cast<double>(current.txBytes) / 1048576.0;

            if (std::abs(totalDown - mTotalWiredDownloadUsage) >= 0.01) {
                mTotalWiredDownloadUsage = totalDown;
                Q_EMIT totalWiredDownloadUsageChanged();
            }
            if (std::abs(totalUp - mTotalWiredUploadUsage) >= 0.01) {
                mTotalWiredUploadUsage = totalUp;
                Q_EMIT totalWiredUploadUsageChanged();
            }

            if (mPreviousNetCounters.contains(mWiredInterface)) {
                const auto   prev      = mPreviousNetCounters.value(mWiredInterface);
                const double downSpeed = sysusage::computeNetSpeedMiBps(prev.rxBytes, current.rxBytes, elapsedSeconds);
                const double upSpeed   = sysusage::computeNetSpeedMiBps(prev.txBytes, current.txBytes, elapsedSeconds);

                if (std::abs(downSpeed - mWiredDownloadSpeed) >= 0.005) {
                    mWiredDownloadSpeed = downSpeed;
                    Q_EMIT wiredDownloadSpeedChanged();
                }
                if (std::abs(upSpeed - mWiredUploadSpeed) >= 0.005) {
                    mWiredUploadSpeed = upSpeed;
                    Q_EMIT wiredUploadSpeedChanged();
                }
            }
        } else {
            resetWiredState();
        }

        // Process wireless interface metrics
        if (!mWirelessInterface.isEmpty() && currentCounters.contains(mWirelessInterface)) {
            const auto   current   = currentCounters.value(mWirelessInterface);
            const double totalDown = static_cast<double>(current.rxBytes) / 1048576.0;
            const double totalUp   = static_cast<double>(current.txBytes) / 1048576.0;

            if (std::abs(totalDown - mTotalWirelessDownloadUsage) >= 0.01) {
                mTotalWirelessDownloadUsage = totalDown;
                Q_EMIT totalWirelessDownloadUsageChanged();
            }
            if (std::abs(totalUp - mTotalWirelessUploadUsage) >= 0.01) {
                mTotalWirelessUploadUsage = totalUp;
                Q_EMIT totalWirelessUploadUsageChanged();
            }

            if (mPreviousNetCounters.contains(mWirelessInterface)) {
                const auto   prev      = mPreviousNetCounters.value(mWirelessInterface);
                const double downSpeed = sysusage::computeNetSpeedMiBps(prev.rxBytes, current.rxBytes, elapsedSeconds);
                const double upSpeed   = sysusage::computeNetSpeedMiBps(prev.txBytes, current.txBytes, elapsedSeconds);

                if (std::abs(downSpeed - mWirelessDownloadSpeed) >= 0.005) {
                    mWirelessDownloadSpeed = downSpeed;
                    Q_EMIT wirelessDownloadSpeedChanged();
                }
                if (std::abs(upSpeed - mWirelessUploadSpeed) >= 0.005) {
                    mWirelessUploadSpeed = upSpeed;
                    Q_EMIT wirelessUploadSpeedChanged();
                }
            }
        } else {
            resetWirelessState();
        }

        mPreviousNetCounters = currentCounters;

        // Check VPN status
        const QString vpn = mSensorScanner.detectVpnStatus();
        if (vpn != mStatusVPNInterface) {
            mStatusVPNInterface = vpn;
            Q_EMIT statusVPNInterfaceChanged();
        }

        // Request wireless bitrate every 8s by deadline, independent of sampleNow() call rate
        if ((!mLastWirelessSample.isValid() || mLastWirelessSample.elapsed() >= WIRELESS_SAMPLE_INTERVAL_MILLISECONDS) && !mWirelessInterface.isEmpty()) {
            if (mWirelessReader->requestBitrateMbps(mWirelessInterface)) {
                mLastWirelessSample.restart();
            }
        }
    }

    void SystemUsageMonitor::sampleStorageAsync() {
        if (mStorageCollectionInFlight)
            return;

        mStorageCollectionInFlight = true;
        const QPointer<SystemUsageMonitor> self(this);
        JobExecutor::instance().post([self]() {
            auto  summary = sysusage::collectStorage();
            auto* app     = QCoreApplication::instance();
            if (!app)
                return;

            QMetaObject::invokeMethod(
                app,
                [self, summary = std::move(summary)]() {
                    if (self.isNull())
                        return;
                    self->applyStorageSummary(summary);
                },
                Qt::QueuedConnection);
        });
    }

    void SystemUsageMonitor::applyStorageSummary(const sysusage::StorageSummary& summary) {
        mStorageCollectionInFlight = false;
        mFilesystemsModel->updateFilesystems(summary.filesystems);

        if (summary.totalKiB != mDiskTotal) {
            mDiskTotal = summary.totalKiB;
            Q_EMIT diskTotalChanged();
        }
        if (summary.totalUsedKiB != mDiskUsed) {
            mDiskUsed = summary.totalUsedKiB;
            Q_EMIT diskUsedChanged();

            const double usedGiB = static_cast<double>(mDiskUsed) / 1048576.0;
            if (std::abs(usedGiB - mDiskUsedGiB) >= 0.001) {
                mDiskUsedGiB = usedGiB;
                Q_EMIT diskUsedGiBChanged();
            }
        }
        const double percent = mDiskTotal > 0 ? (static_cast<double>(mDiskUsed) * 100.0 / static_cast<double>(mDiskTotal)) : 0.0;
        if (std::abs(percent - mDiskPercent) >= 0.01) {
            mDiskPercent = percent;
            Q_EMIT diskPercentChanged();
        }
        if (summary.appsUsedKiB != mStorageAppsData) {
            mStorageAppsData = summary.appsUsedKiB;
            Q_EMIT storageAppsDataChanged();
        }
        if (summary.systemUsedKiB != mStorageSystem) {
            mStorageSystem = summary.systemUsedKiB;
            Q_EMIT storageSystemChanged();
        }
        if (summary.totalFreeKiB != mStorageFree) {
            mStorageFree = summary.totalFreeKiB;
            Q_EMIT storageFreeChanged();
        }
    }

} // namespace vast
