#include "SystemUsageMonitor.hpp"
#include "../Jobs/JobExecutor.hpp"
#include "StorageCollector.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qstringview.h>

#include <sys/utsname.h>
#include <cmath>

namespace vast {

    namespace {

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

                const QString text  = QString::fromUtf8(ueventContent.data(), static_cast<qsizetype>(ueventContent.size()));
                const auto    lines = QStringView(text).split(u'\n');

                QString       pciSlot;
                for (const auto& line : lines) {
                    if (line.startsWith(u"PCI_SLOT_NAME=")) {
                        pciSlot = line.mid(14).trimmed().toString();
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

            // Fallback: run lspci directly if udev data is absent
            QProcess process;
            process.start(QStringLiteral("lspci"), {});
            if (process.waitForFinished(1000)) {
                const QString lspciOut = QString::fromUtf8(process.readAllStandardOutput());
                const auto    lines    = QStringView(lspciOut).split(u'\n');
                for (const auto& line : lines) {
                    if (line.contains(u"VGA compatible controller:", Qt::CaseInsensitive) || line.contains(u"3D controller:", Qt::CaseInsensitive) ||
                        line.contains(u"Display controller:", Qt::CaseInsensitive)) {
                        const qsizetype colon = line.indexOf(u':', line.indexOf(u':') + 1);
                        if (colon >= 0) {
                            return line.mid(colon + 1).trimmed().toString();
                        }
                    }
                }
            }

            return {};
        }

    } // namespace

    SystemUsageMonitor::SystemUsageMonitor(QObject* parent) : QObject(parent), mCpuCoresModel(new CpuCoresModel(this)), mFilesystemsModel(new FilesystemsModel(this)) {
        initializeStaticInfo();

        mTimer = new QTimer(this);
        mTimer->setInterval(2000);
        connect(mTimer, &QTimer::timeout, this, &SystemUsageMonitor::sampleNow);
    }

    void SystemUsageMonitor::setRunning(bool running) {
        if (mRunning == running)
            return;

        mRunning = running;
        emit runningChanged();

        if (mRunning) {
            mLastSampleTime.start();
            sampleNow();
            mTimer->start();
        } else {
            mTimer->stop();
        }
    }

    void SystemUsageMonitor::setWiredInterface(const QString& iface) {
        if (mWiredInterface == iface)
            return;
        mWiredInterface = iface;
        emit wiredInterfaceChanged();
    }

    void SystemUsageMonitor::ensureGraphicsInfoLoaded() {
        if (!mGraphicsProbe) {
            mGraphicsProbe = new GraphicsInfoProbe(this);
            connect(mGraphicsProbe, &GraphicsInfoProbe::finished, this, [this](const sysusage::GraphicsSummary& summary) {
                mGraphicsSummary = summary;
                emit graphicsInfoChanged();
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
        mWirelessInterface   = mSensorScanner.detectWirelessInterface();
    }

    void SystemUsageMonitor::sampleNow() {
        const double elapsedSeconds = mLastSampleTime.isValid() ? static_cast<double>(mLastSampleTime.restart()) / 1000.0 : 2.0;

        sampleCpu();
        sampleMemory();
        sampleUptime();
        sampleSensors();
        sampleNetwork(elapsedSeconds);

        if (mStorageTickCounter % 4 == 0) {
            sampleStorageAsync();
        }
        ++mStorageTickCounter;
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
                emit cpuPercChanged();
            }
        }

        // Sample per-core frequencies and usage
        const auto&         corePaths = mSensorScanner.coreFrequencyPaths();
        QList<CpuCoreEntry> coreEntries;
        coreEntries.reserve(corePaths.size());

        for (const auto& corePair : corePaths) {
            const int        coreId   = corePair.first;
            const QString&   freqPath = corePair.second;

            int              freqMHz     = 0;
            const QByteArray freqContent = readFileTrimmed(freqPath);
            if (auto parsedFreq = sysusage::parseCoreFrequency(freqPath, freqContent)) {
                freqMHz = parsedFreq->second;
            }

            int coreUsage = 0;
            if (mPreviousCpuStat.valid && mPreviousCpuStat.perCore.contains(coreId) && currentStat.perCore.contains(coreId)) {
                coreUsage = sysusage::computeCpuUsagePercent(mPreviousCpuStat.perCore.value(coreId), currentStat.perCore.value(coreId));
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
            emit memTotalChanged();
        }
        if (mem.usedKiB != mMemUsed) {
            mMemUsed = mem.usedKiB;
            emit         memUsedChanged();

            const double prop = static_cast<double>(mMemUsed) / 1048576.0;
            if (std::abs(prop - mMemProp) >= 0.001) {
                mMemProp = prop;
                emit memPropChanged();
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
                emit uptimeFormattedChanged();
            }
        }
    }

    void SystemUsageMonitor::sampleSensors() {
        const double cpuT = mSensorScanner.readCpuTemperature();
        if (std::abs(cpuT - mCpuTemp) >= 0.1) {
            mCpuTemp = cpuT;
            emit cpuTempChanged();
        }

        const double gpuT = mSensorScanner.readGpuTemperature();
        if (std::abs(gpuT - mGpuTemp) >= 0.1) {
            mGpuTemp = gpuT;
            emit gpuTempChanged();
        }

        const double batT = mSensorScanner.readBatteryTemperature();
        if (std::abs(batT - mBatteryTemp) >= 0.1) {
            mBatteryTemp = batT;
            emit batteryTempChanged();
        }
    }

    void SystemUsageMonitor::sampleNetwork(double elapsedSeconds) {
        if (mWirelessInterface.isEmpty()) {
            const QString wireless = mSensorScanner.detectWirelessInterface();
            if (!wireless.isEmpty()) {
                mWirelessInterface = wireless;
                emit wirelessInterfaceChanged();
            }
        }

        const QByteArray netdevContent = readFileTrimmed(QStringLiteral("/proc/net/dev"));
        if (netdevContent.isEmpty())
            return;

        const auto currentCounters = sysusage::parseNetDev(netdevContent);

        // Process wired interface metrics
        if (!mWiredInterface.isEmpty() && currentCounters.contains(mWiredInterface)) {
            const auto   current   = currentCounters.value(mWiredInterface);
            const double totalDown = static_cast<double>(current.rxBytes) / 1048576.0;
            const double totalUp   = static_cast<double>(current.txBytes) / 1048576.0;

            if (std::abs(totalDown - mTotalWiredDownloadUsage) >= 0.01) {
                mTotalWiredDownloadUsage = totalDown;
                emit totalWiredDownloadUsageChanged();
            }
            if (std::abs(totalUp - mTotalWiredUploadUsage) >= 0.01) {
                mTotalWiredUploadUsage = totalUp;
                emit totalWiredUploadUsageChanged();
            }

            if (mPreviousNetCounters.contains(mWiredInterface)) {
                const auto   prev      = mPreviousNetCounters.value(mWiredInterface);
                const double downSpeed = sysusage::computeNetSpeedMBps(prev.rxBytes, current.rxBytes, elapsedSeconds);
                const double upSpeed   = sysusage::computeNetSpeedMBps(prev.txBytes, current.txBytes, elapsedSeconds);

                if (std::abs(downSpeed - mWiredDownloadSpeed) >= 0.005) {
                    mWiredDownloadSpeed = downSpeed;
                    emit wiredDownloadSpeedChanged();
                }
                if (std::abs(upSpeed - mWiredUploadSpeed) >= 0.005) {
                    mWiredUploadSpeed = upSpeed;
                    emit wiredUploadSpeedChanged();
                }
            }
        } else if (mWiredDownloadSpeed > 0.0 || mWiredUploadSpeed > 0.0) {
            mWiredDownloadSpeed = 0.0;
            mWiredUploadSpeed   = 0.0;
            emit wiredDownloadSpeedChanged();
            emit wiredUploadSpeedChanged();
        }

        // Process wireless interface metrics
        if (!mWirelessInterface.isEmpty() && currentCounters.contains(mWirelessInterface)) {
            const auto   current   = currentCounters.value(mWirelessInterface);
            const double totalDown = static_cast<double>(current.rxBytes) / 1048576.0;
            const double totalUp   = static_cast<double>(current.txBytes) / 1048576.0;

            if (std::abs(totalDown - mTotalWirelessDownloadUsage) >= 0.01) {
                mTotalWirelessDownloadUsage = totalDown;
                emit totalWirelessDownloadUsageChanged();
            }
            if (std::abs(totalUp - mTotalWirelessUploadUsage) >= 0.01) {
                mTotalWirelessUploadUsage = totalUp;
                emit totalWirelessUploadUsageChanged();
            }

            if (mPreviousNetCounters.contains(mWirelessInterface)) {
                const auto   prev      = mPreviousNetCounters.value(mWirelessInterface);
                const double downSpeed = sysusage::computeNetSpeedMBps(prev.rxBytes, current.rxBytes, elapsedSeconds);
                const double upSpeed   = sysusage::computeNetSpeedMBps(prev.txBytes, current.txBytes, elapsedSeconds);

                if (std::abs(downSpeed - mWirelessDownloadSpeed) >= 0.005) {
                    mWirelessDownloadSpeed = downSpeed;
                    emit wirelessDownloadSpeedChanged();
                }
                if (std::abs(upSpeed - mWirelessUploadSpeed) >= 0.005) {
                    mWirelessUploadSpeed = upSpeed;
                    emit wirelessUploadSpeedChanged();
                }
            }
        } else if (mWirelessDownloadSpeed > 0.0 || mWirelessUploadSpeed > 0.0) {
            mWirelessDownloadSpeed = 0.0;
            mWirelessUploadSpeed   = 0.0;
            emit wirelessDownloadSpeedChanged();
            emit wirelessUploadSpeedChanged();
        }

        mPreviousNetCounters = currentCounters;

        // Check VPN status
        const QString vpn = mSensorScanner.detectVpnStatus();
        if (vpn != mStatusVPNInterface) {
            mStatusVPNInterface = vpn;
            emit statusVPNInterfaceChanged();
        }

        // Query wireless bitrate every 4 ticks (8s)
        if (mStorageTickCounter % 4 == 0 && !mWirelessInterface.isEmpty()) {
            const int linkSpeed = mWirelessReader.queryBitrateMbps(mWirelessInterface);
            if (linkSpeed != mWirelessLinkSpeed) {
                mWirelessLinkSpeed = linkSpeed;
                emit wirelessLinkSpeedChanged();
            }
        }
    }

    void SystemUsageMonitor::sampleStorageAsync() {
        JobExecutor::instance().post([this]() {
            auto summary = StorageCollector::collect();

            QMetaObject::invokeMethod(
                this,
                [this, summary = std::move(summary)]() {
                    mFilesystemsModel->updateFilesystems(summary.filesystems);

                    if (summary.totalKiB != mDiskTotal) {
                        mDiskTotal = summary.totalKiB;
                        emit diskTotalChanged();
                    }
                    if (summary.totalUsedKiB != mDiskUsed) {
                        mDiskUsed = summary.totalUsedKiB;
                        emit         diskUsedChanged();

                        const double prop = static_cast<double>(mDiskUsed) / 1048576.0;
                        if (std::abs(prop - mDiskProp) >= 0.001) {
                            mDiskProp = prop;
                            emit diskPropChanged();
                        }
                    }
                    const double percent = mDiskTotal > 0 ? (static_cast<double>(mDiskUsed) * 100.0 / static_cast<double>(mDiskTotal)) : 0.0;
                    if (std::abs(percent - mDiskPercent) >= 0.01) {
                        mDiskPercent = percent;
                        emit diskPercentChanged();
                    }
                    if (summary.appsUsedKiB != mStorageAppsData) {
                        mStorageAppsData = summary.appsUsedKiB;
                        emit storageAppsDataChanged();
                    }
                    if (summary.systemUsedKiB != mStorageSystem) {
                        mStorageSystem = summary.systemUsedKiB;
                        emit storageSystemChanged();
                    }
                    if (summary.totalFreeKiB != mStorageFree) {
                        mStorageFree = summary.totalFreeKiB;
                        emit storageFreeChanged();
                    }
                },
                Qt::QueuedConnection);
        });
    }

} // namespace vast
