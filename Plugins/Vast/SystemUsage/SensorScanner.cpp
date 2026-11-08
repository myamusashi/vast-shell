#include "SensorScanner.hpp"
#include "SystemStatParsers.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstringview.h>

#include <algorithm>

namespace vast {

    namespace {

        [[nodiscard]] QByteArray readAllTrimmed(const QString& filePath) {
            QFile file(filePath);
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
                return {};
            return file.readAll().trimmed();
        }

        [[nodiscard]] double parseTemperatureValue(const QString& filePath) {
            const QByteArray content = readAllTrimmed(filePath);
            if (content.isEmpty())
                return 0.0;

            bool         ok       = false;
            const double rawValue = content.toDouble(&ok);
            if (!ok || rawValue <= 0.0)
                return 0.0;

            if (rawValue > 1000.0) {
                return rawValue / 1000.0;
            }
            if (rawValue > 100.0) {
                return rawValue / 10.0;
            }
            return rawValue;
        }

    } // namespace

    SensorScanner::SensorScanner(const QString& sysRoot) : mSysRoot(sysRoot), mCoreFrequencyPaths() {}

    void SensorScanner::scan() {
        scanHwmonSensors();
        scanBatterySensors();
        scanCpuFreqPaths();
    }

    void SensorScanner::scanHwmonSensors() {
        mCpuTempPath.clear();
        mGpuTempPath.clear();

        // 1. Scan /sys/class/hwmon/hwmon*
        const QDir hwmonDir(mSysRoot + u"/class/hwmon");
        const auto hwmonEntries = hwmonDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

        QString    preferredCpuInput;
        QString    fallbackCpuInput;
        QString    preferredGpuInput;
        QString    fallbackGpuInput;

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

                if (isIntelCpu) {
                    if (label.contains(u"Package id", Qt::CaseInsensitive) || label.contains(u"Physical id", Qt::CaseInsensitive)) {
                        preferredCpuInput = inputPath;
                    } else if (fallbackCpuInput.isEmpty() && label.contains(u"Core 0", Qt::CaseInsensitive)) {
                        fallbackCpuInput = inputPath;
                    } else if (fallbackCpuInput.isEmpty()) {
                        fallbackCpuInput = inputPath;
                    }
                } else if (isAmdCpu) {
                    if (label.contains(u"Tdie", Qt::CaseInsensitive)) {
                        preferredCpuInput = inputPath;
                    } else if (label.contains(u"Tctl", Qt::CaseInsensitive) && preferredCpuInput.isEmpty()) {
                        preferredCpuInput = inputPath;
                    } else if (fallbackCpuInput.isEmpty()) {
                        fallbackCpuInput = inputPath;
                    }
                } else if (isGenericCpu && fallbackCpuInput.isEmpty()) {
                    fallbackCpuInput = inputPath;
                }

                if (isGpu) {
                    if (label.contains(u"edge", Qt::CaseInsensitive) || label.contains(u"junction", Qt::CaseInsensitive)) {
                        preferredGpuInput = inputPath;
                    } else if (fallbackGpuInput.isEmpty()) {
                        fallbackGpuInput = inputPath;
                    }
                }
            }
        }

        mCpuTempPath = !preferredCpuInput.isEmpty() ? preferredCpuInput : fallbackCpuInput;

        // 2. Scan /sys/class/drm/card*/device/hwmon/hwmon*/temp1_input for GPU temp if not found
        if (mGpuTempPath.isEmpty()) {
            const QString candidateGpu = !preferredGpuInput.isEmpty() ? preferredGpuInput : fallbackGpuInput;
            if (!candidateGpu.isEmpty()) {
                mGpuTempPath = candidateGpu;
            } else {
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
                            mGpuTempPath = tempInput;
                            break;
                        }
                    }
                    if (!mGpuTempPath.isEmpty())
                        break;
                }
            }
        }
    }

    void SensorScanner::scanBatterySensors() {
        mBatteryTempPath.clear();
        mBatteryTechPath.clear();

        const QDir powerDir(mSysRoot + u"/class/power_supply");
        const auto batteries = powerDir.entryList(QStringList{QStringLiteral("BAT*"), QStringLiteral("battery")}, QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);
        for (const auto& battery : batteries) {
            const QString batteryPath = powerDir.absoluteFilePath(battery);
            const QString tempFile    = batteryPath + u"/temp";
            const QString techFile    = batteryPath + u"/technology";

            if (QFile::exists(tempFile) && mBatteryTempPath.isEmpty()) {
                mBatteryTempPath = tempFile;
            }
            if (QFile::exists(techFile) && mBatteryTechPath.isEmpty()) {
                mBatteryTechPath = techFile;
            }
            if (!mBatteryTempPath.isEmpty() && !mBatteryTechPath.isEmpty())
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
                mCoreFrequencyPaths.append(qMakePair(coreId, freqPath));
            }
        }

        std::sort(mCoreFrequencyPaths.begin(), mCoreFrequencyPaths.end(), [](const auto& first, const auto& second) { return first.first < second.first; });
    }

    double SensorScanner::readCpuTemperature() const {
        if (mCpuTempPath.isEmpty())
            return 0.0;
        return parseTemperatureValue(mCpuTempPath);
    }

    double SensorScanner::readGpuTemperature() const {
        if (mGpuTempPath.isEmpty())
            return 0.0;
        return parseTemperatureValue(mGpuTempPath);
    }

    double SensorScanner::readBatteryTemperature() const {
        if (mBatteryTempPath.isEmpty())
            return 0.0;
        return parseTemperatureValue(mBatteryTempPath);
    }

    QString SensorScanner::readBatteryTechnology() const {
        if (mBatteryTechPath.isEmpty())
            return {};
        return QString::fromUtf8(readAllTrimmed(mBatteryTechPath));
    }

    QString SensorScanner::detectWirelessInterface() const {
        const QDir netDir(mSysRoot + u"/class/net");
        const auto interfaces = netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

        for (const auto& iface : interfaces) {
            if (QFile::exists(netDir.absoluteFilePath(iface) + u"/wireless")) {
                return iface;
            }
        }

        return {};
    }

    QString SensorScanner::detectVpnStatus() const {
        const QDir netDir(mSysRoot + u"/class/net");
        const auto interfaces = netDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot, QDir::Name);

        for (const auto& iface : interfaces) {
            const QString ifacePath = netDir.absoluteFilePath(iface);
            const QString operstate = QString::fromUtf8(readAllTrimmed(ifacePath + u"/operstate"));
            if (operstate == u"down")
                continue;

            const QByteArray uevent = readAllTrimmed(ifacePath + u"/uevent");
            if (uevent.contains("DEVTYPE=wireguard") || iface.startsWith(u"wg") || iface.startsWith(u"tun") || iface.startsWith(u"tap") ||
                iface.contains(u"CloudflareWARP", Qt::CaseInsensitive)) {
                return QStringLiteral("connected");
            }
        }

        return QStringLiteral("disconnected");
    }

} // namespace vast
