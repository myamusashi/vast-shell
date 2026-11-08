#include "SensorScanner.hpp"
#include "SystemStatParsers.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstringview.h>

#include <algorithm>
#include <limits>
#include <ranges>
#include <utility>

namespace vast {

    namespace {

        [[nodiscard]] QByteArray readAllTrimmed(const QString& filePath) {
            QFile file(filePath);
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                return {};
            return file.readAll().trimmed();
        }

        [[nodiscard]] std::optional<double> parseTemperatureValue(const QString& filePath, double divisor) {
            const QByteArray content = readAllTrimmed(filePath);
            if (content.isEmpty())
                return std::nullopt;

            bool         ok       = false;
            const double rawValue = content.toDouble(&ok);
            if (!ok)
                return std::nullopt;

            const double scaledValue = rawValue / divisor;
            if (scaledValue < -50.0 || scaledValue > 150.0)
                return std::nullopt;

            return scaledValue;
        }

        [[nodiscard]] bool hasNumericSuffix(QStringView name, QStringView prefix) {
            if (!name.startsWith(prefix))
                return false;
            const auto suffix = name.mid(prefix.size());
            return !suffix.isEmpty() && std::ranges::all_of(suffix, [](QChar character) { return character.isDigit(); });
        }

        [[nodiscard]] bool isVpnName(QStringView interfaceName) {
            return hasNumericSuffix(interfaceName, u"tun") || hasNumericSuffix(interfaceName, u"tap") || interfaceName.startsWith(u"wg") ||
                interfaceName.contains(u"CloudflareWARP", Qt::CaseInsensitive);
        }

        struct SensorCandidate {
            QString path;
            int     rank{std::numeric_limits<int>::max()};
        };

    } // namespace

    SensorScanner::SensorScanner(QString sysRoot) : mSysRoot(std::move(sysRoot)) {}

    void SensorScanner::scan() {
        scanHwmonSensors();
        scanBatterySensors();
        scanCpuFreqPaths();
    }

    void SensorScanner::scanHwmonSensors() {
        mCpuTemperatureSource = TemperatureSource{};
        mGpuTemperatureSource = TemperatureSource{};

        // 1. Scan /sys/class/hwmon/hwmon*; lower rank wins, first seen wins on ties
        const QDir      hwmonDir(mSysRoot + u"/class/hwmon");
        const auto      hwmonEntries = hwmonDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

        SensorCandidate bestCpuCandidate;
        SensorCandidate bestGpuCandidate;

        for (const auto& hwmonInfo : hwmonEntries) {
            const QString hwmonPath  = hwmonInfo.absoluteFilePath();
            const QString driverName = QString::fromUtf8(readAllTrimmed(hwmonPath + u"/name"));

            const QDir    dir(hwmonPath);
            const auto    inputFiles   = dir.entryList(QStringList{QStringLiteral("temp*_input")}, QDir::Files, QDir::Name);
            const bool    isIntelCpu   = driverName == u"coretemp";
            const bool    isAmdCpu     = driverName == u"k10temp" || driverName == u"zenpower";
            const bool    isGenericCpu = driverName.contains(u"cpu", Qt::CaseInsensitive) || driverName == u"acpitz";
            const bool    isGpu        = driverName == u"amdgpu" || driverName == u"nouveau" || driverName == u"i915" || driverName == u"xe";

            for (const auto& inputFile : inputFiles) {
                const QString inputPath = hwmonPath + u'/' + inputFile;
                const QString labelFile = inputFile.left(inputFile.size() - 5) + u"label";
                const QString label     = QString::fromUtf8(readAllTrimmed(hwmonPath + u'/' + labelFile));

                int           cpuRank = std::numeric_limits<int>::max();
                if ((isIntelCpu && (label.contains(u"Package id", Qt::CaseInsensitive) || label.contains(u"Physical id", Qt::CaseInsensitive))) ||
                    (isAmdCpu && label.contains(u"Tdie", Qt::CaseInsensitive)))
                    cpuRank = 0;
                else if (isAmdCpu && label.contains(u"Tctl", Qt::CaseInsensitive))
                    cpuRank = 1;
                else if (isIntelCpu || isAmdCpu)
                    cpuRank = 2;
                else if (isGenericCpu)
                    cpuRank = 3;

                if (cpuRank < bestCpuCandidate.rank)
                    bestCpuCandidate = SensorCandidate{.path = inputPath, .rank = cpuRank};

                if (isGpu) {
                    const int gpuRank = (label.contains(u"edge", Qt::CaseInsensitive) || label.contains(u"junction", Qt::CaseInsensitive)) ? 0 : 1;
                    if (gpuRank < bestGpuCandidate.rank)
                        bestGpuCandidate = SensorCandidate{.path = inputPath, .rank = gpuRank};
                }
            }
        }

        if (!bestCpuCandidate.path.isEmpty())
            mCpuTemperatureSource = TemperatureSource{.path = bestCpuCandidate.path, .divisor = 1000.0};
        if (!bestGpuCandidate.path.isEmpty())
            mGpuTemperatureSource = TemperatureSource{.path = bestGpuCandidate.path, .divisor = 1000.0};

        // 2. Scan /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input for GPU temp if not found
        if (mGpuTemperatureSource.path.isEmpty()) {
            const QDir drmDir(mSysRoot + u"/class/drm");
            const auto cards = drmDir.entryList(QStringList{QStringLiteral("card*")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
            for (const auto& card : cards) {
                if (card.contains(u'-'))
                    continue;
                const QDir cardHwmonDir(mSysRoot + u"/class/drm/" + card + u"/device/hwmon");
                const auto cardHwmons = cardHwmonDir.entryList(QStringList{QStringLiteral("hwmon*")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
                for (const auto& subHwmon : cardHwmons) {
                    const QString tempInput = cardHwmonDir.absoluteFilePath(subHwmon) + u"/temp1_input";
                    if (QFile::exists(tempInput)) {
                        mGpuTemperatureSource = TemperatureSource{.path = tempInput, .divisor = 1000.0};
                        break;
                    }
                }
                if (!mGpuTemperatureSource.path.isEmpty())
                    break;
            }
        }
    }

    void SensorScanner::scanBatterySensors() {
        mBatteryTemperatureSource = TemperatureSource{};
        mBatteryTechPath.clear();

        const QDir powerDir(mSysRoot + u"/class/power_supply");
        const auto batteries = powerDir.entryList(QStringList{QStringLiteral("BAT*"), QStringLiteral("battery")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const auto& battery : batteries) {
            const QString batteryPath = powerDir.absoluteFilePath(battery);
            const QString tempFile    = batteryPath + u"/temp";
            const QString techFile    = batteryPath + u"/technology";

            if (QFile::exists(tempFile) && mBatteryTemperatureSource.path.isEmpty()) {
                mBatteryTemperatureSource = TemperatureSource{.path = tempFile, .divisor = 10.0};
            }
            if (QFile::exists(techFile) && mBatteryTechPath.isEmpty()) {
                mBatteryTechPath = techFile;
            }
            if (!mBatteryTemperatureSource.path.isEmpty() && !mBatteryTechPath.isEmpty())
                break;
        }
    }

    void SensorScanner::scanCpuFreqPaths() {
        mCoreFrequencyPaths.clear();

        const QDir cpuDir(mSysRoot + u"/devices/system/cpu");
        const auto cpuEntries = cpuDir.entryList(QStringList{QStringLiteral("cpu[0-9]*")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const auto& entry : cpuEntries) {
            const QString freqPath = cpuDir.absoluteFilePath(entry) + u"/cpufreq/scaling_cur_freq";
            if (!QFile::exists(freqPath))
                continue;

            const auto coreIndexString = QStringView(entry).mid(3);
            bool       ok              = false;
            const int  coreId          = coreIndexString.toInt(&ok);
            if (ok) {
                mCoreFrequencyPaths.append(SensorCoreInfo{.coreId = coreId, .frequencyPath = freqPath});
            }
        }

        std::ranges::sort(mCoreFrequencyPaths, {}, &SensorCoreInfo::coreId);
    }

    std::optional<double> SensorScanner::readCpuTemperature() const {
        if (mCpuTemperatureSource.path.isEmpty())
            return std::nullopt;
        return parseTemperatureValue(mCpuTemperatureSource.path, mCpuTemperatureSource.divisor);
    }

    std::optional<double> SensorScanner::readGpuTemperature() const {
        if (mGpuTemperatureSource.path.isEmpty())
            return std::nullopt;
        return parseTemperatureValue(mGpuTemperatureSource.path, mGpuTemperatureSource.divisor);
    }

    std::optional<double> SensorScanner::readBatteryTemperature() const {
        if (mBatteryTemperatureSource.path.isEmpty())
            return std::nullopt;
        return parseTemperatureValue(mBatteryTemperatureSource.path, mBatteryTemperatureSource.divisor);
    }

    QString SensorScanner::readBatteryTechnology() const {
        if (mBatteryTechPath.isEmpty())
            return {};
        return QString::fromUtf8(readAllTrimmed(mBatteryTechPath));
    }

    void SensorScanner::updateInterfaces(const QList<QString>& names) {
        QList<QString> sortedNames = names;
        std::ranges::sort(sortedNames);
        if (sortedNames == mInterfaceNames)
            return;

        mInterfaceNames  = std::move(sortedNames);
        mWirelessScanned = false;
        mCachedWirelessInterface.clear();
        mVpnCandidates.clear();

        if (mInterfaceNames.isEmpty())
            return;

        refreshVpnCandidates();
    }

    QString SensorScanner::detectWirelessInterface() {
        if (!mWirelessScanned) {
            mCachedWirelessInterface = scanWirelessInterface();
            mWirelessScanned         = true;
        }
        return mCachedWirelessInterface;
    }

    QString SensorScanner::detectVpnStatus() {
        for (const auto& candidate : std::as_const(mVpnCandidates)) {
            const QString ifacePath = mSysRoot + u"/class/net/" + candidate;
            const QString operstate = QString::fromUtf8(readAllTrimmed(ifacePath + u"/operstate"));
            if (operstate == u"up" || operstate == u"unknown")
                return QStringLiteral("connected");
        }

        return QStringLiteral("disconnected");
    }

    void SensorScanner::refreshVpnCandidates() {
        mVpnCandidates.clear();
        for (const auto& candidate : std::as_const(mInterfaceNames)) {
            if (isVpnName(candidate)) {
                mVpnCandidates.append(candidate);
                continue;
            }
            const QByteArray uevent = readAllTrimmed(mSysRoot + u"/class/net/" + candidate + u"/uevent");
            if (uevent.contains("DEVTYPE=wireguard"))
                mVpnCandidates.append(candidate);
        }
    }

    QString SensorScanner::scanWirelessInterface() const {
        const QDir netDir(mSysRoot + u"/class/net");
        const auto interfaces = netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

        for (const auto& iface : interfaces) {
            if (QFile::exists(netDir.absoluteFilePath(iface) + u"/wireless")) {
                return iface;
            }
        }

        return {};
    }

} // namespace vast
