#include "../../SystemUsage/CpuCoresModel.hpp"
#include "../../SystemUsage/FilesystemsModel.hpp"
#include "../../SystemUsage/GraphicsInfoProbe.hpp"
#include "../../SystemUsage/SensorScanner.hpp"
#include "../../SystemUsage/SystemFormatters.hpp"
#include "../../SystemUsage/SystemStatParsers.hpp"
#include "../../SystemUsage/SystemUsageMonitor.hpp"
#include "../../SystemUsage/WirelessBitrateReader.hpp"

#include <qbytearray.h>
#include <qcoreapplication.h>
#include <qdbusconnection.h>
#include <qdbuscontext.h>
#include <qdbuserror.h>
#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtemporarydir.h>
#include <qtest.h>

#include <algorithm>
#include <memory>
#include <optional>
#include <utility>
#include <vector>

using namespace vast;
using namespace vast::sysusage;

namespace {

    constexpr const char* BUS_CONFIG_TEMPLATE = "<busconfig>\n"
                                                "  <type>session</type>\n"
                                                "  <listen>%1</listen>\n"
                                                "  <keep_umask/>\n"
                                                "  <policy context=\"default\">\n"
                                                "    <allow user=\"*\"/>\n"
                                                "    <allow own=\"*\"/>\n"
                                                "    <allow send_type=\"method_call\"/>\n"
                                                "    <allow send_type=\"method_return\"/>\n"
                                                "    <allow send_type=\"error\"/>\n"
                                                "    <allow send_type=\"signal\"/>\n"
                                                "    <allow receive_type=\"method_call\"/>\n"
                                                "    <allow receive_type=\"method_return\"/>\n"
                                                "    <allow receive_type=\"error\"/>\n"
                                                "    <allow receive_type=\"signal\"/>\n"
                                                "  </policy>\n"
                                                "</busconfig>\n";

    class FakeNetworkManager final : public QObject, public QDBusContext {
        Q_OBJECT
        Q_CLASSINFO("D-Bus Interface", "org.freedesktop.NetworkManager")

      public:
        explicit FakeNetworkManager(QObject* parent = nullptr) : QObject(parent) {}

        Q_INVOKABLE QDBusObjectPath GetDeviceByIpIface(const QString& interfaceName) {
            if (interfaceName == u"wlan0")
                return QDBusObjectPath(QStringLiteral("/org/freedesktop/NetworkManager/Devices/42"));
            if (interfaceName == u"empty-path")
                return QDBusObjectPath(QStringLiteral("/"));
            if (interfaceName == u"ghost")
                return QDBusObjectPath(QStringLiteral("/org/freedesktop/NetworkManager/Devices/404"));
            if (interfaceName == u"error-iface") {
                sendErrorReply(QDBusError::Failed, QStringLiteral("Scripted error"));
                return QDBusObjectPath();
            }
            sendErrorReply(QDBusError::UnknownInterface, QStringLiteral("No such interface"));
            return QDBusObjectPath();
        }
    };

    class FakeWirelessDevice final : public QObject {
        Q_OBJECT
        Q_CLASSINFO("D-Bus Interface", "org.freedesktop.NetworkManager.Device.Wireless")
        Q_PROPERTY(unsigned int Bitrate READ bitrate)

      public:
        explicit FakeWirelessDevice(QObject* parent = nullptr) : QObject(parent) {}

        [[nodiscard]] unsigned int bitrate() const {
            return 576000;
        }
    };

    struct FakeBus {
        FakeNetworkManager networkManager;
        FakeWirelessDevice device;
        QDBusConnection    connection;

        explicit FakeBus(QDBusConnection conn) : connection(std::move(conn)) {}

        ~FakeBus() {
            if (!connection.isConnected())
                return;
            connection.unregisterObject(QStringLiteral("/org/freedesktop/NetworkManager"));
            connection.unregisterObject(QStringLiteral("/org/freedesktop/NetworkManager/Devices/42"));
        }

        void setup() {
            connection.registerObject(QStringLiteral("/org/freedesktop/NetworkManager"), &networkManager,
                                      QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllInvokables | QDBusConnection::ExportAllSignals);
            connection.registerObject(QStringLiteral("/org/freedesktop/NetworkManager/Devices/42"), &device,
                                      QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllInvokables | QDBusConnection::ExportAllSignals |
                                          QDBusConnection::ExportAllProperties | QDBusConnection::ExportScriptableProperties);
        }
    };

    [[nodiscard]] bool writeSysfsFile(const QTemporaryDir& sysRoot, QStringView relativePath, const QByteArray& content) {
        const QString absolutePath = sysRoot.path() + u'/' + relativePath;
        if (!QDir().mkpath(QFileInfo(absolutePath).absolutePath()))
            return false;
        QFile file(absolutePath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            return false;
        return file.write(content) == content.size();
    }

    [[nodiscard]] bool writeSensorFixture(const QTemporaryDir& sysRoot, const QString& driverName, const QList<std::pair<QString, QString>>& labeledInputs) {
        if (!writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/name", (driverName + u"\n").toUtf8()))
            return false;
        int index = 1;
        for (const auto& [label, rawValue] : labeledInputs) {
            if (!writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/temp" + QString::number(index) + u"_label", (label + u"\n").toUtf8()))
                return false;
            if (!writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/temp" + QString::number(index) + u"_input", (rawValue + u"\n").toUtf8()))
                return false;
            ++index;
        }
        return true;
    }

    [[nodiscard]] bool writeFakeTool(const QTemporaryDir& toolDirectory, const QString& toolName, const QByteArray& script) {
        const QString absolutePath = toolDirectory.path() + u'/' + toolName;
        QFile         file(absolutePath);
        if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
            return false;
        if (file.write("#!/bin/sh\n") < 0)
            return false;
        if (file.write(script) != script.size())
            return false;
        file.close();
        return file.setPermissions(QFileDevice::ExeOwner | QFileDevice::ExeGroup | QFileDevice::ExeOther | QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    }

    struct FakeToolPath {
        QByteArray    previousPath;
        QTemporaryDir toolDirectory;
        QTemporaryDir driDirectory;

        FakeToolPath() : previousPath(qgetenv("PATH")) {
            qputenv("PATH", toolDirectory.path().toUtf8());
        }

        ~FakeToolPath() {
            qputenv("PATH", previousPath);
        }

        [[nodiscard]] bool createFakeDriNode() {
            QFile file(driDirectory.path() + u"/renderD128");
            return file.open(QIODevice::WriteOnly);
        }
    };

} // namespace

#define REQUIRE_BUS()                                                                                                                                                              \
    do {                                                                                                                                                                           \
        if (mHaveBus)                                                                                                                                                              \
            break;                                                                                                                                                                 \
        if (!qEnvironmentVariableIsSet("CI"))                                                                                                                                      \
            QSKIP("no private bus");                                                                                                                                               \
        QFAIL("private dbus-daemon was not available in test");                                                                                                                    \
    } while (false)

class tst_SystemUsage : public QObject {
    Q_OBJECT

  private slots:
    void initTestCase();
    void cleanupTestCase();

    void testMemInfo64BitOverflow();
    void testCpuStatJiffiesOverflow();
    void testCpuJiffiesCompletenessAndReset();
    void testParseFrequencyMHzValues();
    void testCoreFrequencyPathsNumericOrdering();
    void testNonContiguousCpuCores();
    void testSensorScannerIntelAmdAndMissing();
    void testFilesystemDeduplication();
    void testFilesystemDeduplicationUsedPercentDerived();
    void testNetDevParsingAndReset();
    void testCpuCoresModelIncrementalSignals();
    void testFilesystemsModelIncrementalSignals();
    void testFilesystemsModelResetsWhenDeviceSetChanges();
    void testFormatters();
    void testOsReleaseAndCpuInfoParsers();
    void testUdevPciGpuParser();
    void testParseCpuStatMalformed();
    void testParseMemInfoMalformed();
    void testParseNetDevMalformed();
    void testParseOsReleaseMalformed();
    void testParseUdevPciGpuNameMalformed();
    void testParseGraphicsOutputs();
    void testGraphicsProbeSuccess();
    void testGraphicsProbeToolsMissing();
    void testGraphicsProbeToolCrash();
    void testGraphicsProbeToolNonZeroExit();
    void testGraphicsProbeToolHangs();
    void testGraphicsProbeEglinfoEmptyFallsBackToGlxinfo();
    void testGraphicsProbeEglinfoFailsFallsBackToGlxinfo();
    void testGraphicsProbeNoDriDeviceGoesStraightToGlxinfo();
    void testGraphicsProbeNonZeroExitWithOutputVulkanAndGlxinfo();
    void testGraphicsProbeVaApiNonzeroExitWithOutput();
    void testGraphicsProbeFinishedAlwaysAsync();
    void testParseLspciGpuName();
    void testSensorScannerTctlBeatsGeneric();
    void testSensorScannerIntelPackageAfterCores();
    void testSensorScannerTemperatureSanityRange();
    void testSensorScannerNegativeTemperatureAccepted();
    void testSensorScannerVpnNameClassification();
    void testSensorScannerVpnWireguardCustomName();
    void testSensorScannerVpnOperstateFlip();
    void testSensorScannerInterfaceAppearDisappear();
    void testSensorScannerWirelessReplug();
    void testSensorScannerWiredOnlyInterfaceCache();
    void testSensorScannerUnorderedInterfacesNoRescan();
    void testParseFrequencyMHzMalformed();
    void testWirelessBitrateSuccess();
    void testWirelessBitrateEmptyPath();
    void testWirelessBitrateUnknownInterface();
    void testWirelessBitrateDBusError();
    void testWirelessBitratePropertyErrorAndStalePath();
    void testWirelessBitrateConcurrentRequestIgnored();
    void testSystemUsageMonitorNetworkUnplug();
    void testSystemUsageMonitorLspci();

  private:
    std::unique_ptr<QTemporaryDir> mBusDir;
    QProcess                       mDaemon;
    QString                        mBusAddress;
    std::optional<QDBusConnection> mBus;
    bool                           mHaveBus{false};
};

void tst_SystemUsage::initTestCase() {
    mBusDir = std::make_unique<QTemporaryDir>();
    if (!mBusDir->isValid())
        return;

    const QString socketPath = mBusDir->filePath(QStringLiteral("bus"));
    const QString configPath = mBusDir->filePath(QStringLiteral("session.conf"));
    {
        QFile config(configPath);
        if (!config.open(QIODeviceBase::WriteOnly | QIODeviceBase::Text))
            return;
        config.write(QString::fromLatin1(BUS_CONFIG_TEMPLATE).arg(QStringLiteral("unix:path=%1").arg(socketPath)).toLatin1());
        config.close();
    }

    mDaemon.start(QStringLiteral("dbus-daemon"), {QStringLiteral("--config-file=%1").arg(configPath), QStringLiteral("--print-address"), QStringLiteral("--nofork")});
    if (!mDaemon.waitForStarted(5000))
        return;

    if (mDaemon.waitForReadyRead(5000))
        mBusAddress = QString::fromUtf8(mDaemon.readLine()).trimmed();
    if (mBusAddress.isEmpty())
        return;

    mBus.emplace(QDBusConnection::connectToBus(mBusAddress, QStringLiteral("tst-sysusage-bus")));
    if (!mBus->isConnected())
        return;

    mHaveBus = true;
}

void tst_SystemUsage::cleanupTestCase() {
    if (mBus) {
        mBus.reset();
        QDBusConnection::disconnectFromBus(QStringLiteral("tst-sysusage-bus"));
    }
    if (mDaemon.state() == QProcess::Running) {
        mDaemon.terminate();
        mDaemon.waitForFinished(2000);
    }
}

void tst_SystemUsage::testMemInfo64BitOverflow() {
    const QByteArray      meminfo = "MemTotal:        67108864 kB\n"
                                    "MemFree:         33554432 kB\n"
                                    "MemAvailable:    50331648 kB\n";

    const MemInfoSnapshot snapshot = parseMemInfo(meminfo);
    QVERIFY(snapshot.valid);
    QCOMPARE(snapshot.totalKiB, 67108864ULL);
    QCOMPARE(snapshot.availableKiB, 50331648ULL);
    QCOMPARE(snapshot.usedKiB, 16777216ULL);

    QCOMPARE(formatKiB(snapshot.totalKiB), QStringLiteral("64.00 GiB"));
    QCOMPARE(formatKiB(snapshot.usedKiB), QStringLiteral("16.00 GiB"));

    // 4 TiB memory test
    const QByteArray      hugeMeminfo  = "MemTotal:        4294967296 kB\n"
                                         "MemAvailable:    2147483648 kB\n";
    const MemInfoSnapshot hugeSnapshot = parseMemInfo(hugeMeminfo);
    QVERIFY(hugeSnapshot.valid);
    QCOMPARE(hugeSnapshot.totalKiB, 4294967296ULL);
    QCOMPARE(hugeSnapshot.usedKiB, 2147483648ULL);
    QCOMPARE(formatKiB(hugeSnapshot.totalKiB), QStringLiteral("4096.00 GiB"));
}

void tst_SystemUsage::testCpuStatJiffiesOverflow() {
    const QByteArray      stat1 = "cpu  5000000000 1000000 2000000 10000000000 500000 100000 200000 300000 0 0\n";
    const QByteArray      stat2 = "cpu  5000100000 1000000 2000000 10000100000 500000 100000 200000 300000 0 0\n";

    const CpuStatSnapshot snap1 = parseCpuStat(stat1);
    const CpuStatSnapshot snap2 = parseCpuStat(stat2);

    QVERIFY(snap1.valid);
    QVERIFY(snap2.valid);
    QCOMPARE(snap1.aggregate.user, 5000000000ULL);
    QCOMPARE(snap1.aggregate.idle, 10000000000ULL);

    // Delta: user increased by 100,000, idle increased by 100,000 -> 50% usage
    const int usage = computeCpuUsagePercent(snap1.aggregate, snap2.aggregate);
    QCOMPARE(usage, 50);
}

void tst_SystemUsage::testCpuJiffiesCompletenessAndReset() {
    // 50% of delta in irq + softirq + steal
    CpuJiffies prev{.user = 1000, .nice = 0, .system = 1000, .idle = 8000, .iowait = 0, .irq = 0, .softirq = 0, .steal = 0};
    CpuJiffies curr{.user = 1000, .nice = 0, .system = 1000, .idle = 9000, .iowait = 0, .irq = 300, .softirq = 300, .steal = 400};

    // total delta = (1000-1000) + (1000-1000) + (9000-8000 idle=1000) + (300+300+400 active=1000) = 2000.
    // active delta = 1000 -> 50%
    const int usage = computeCpuUsagePercent(prev, curr);
    QCOMPARE(usage, 50);

    // Counter reset: curr.total() < prev.total()
    CpuJiffies resetJiffies{.user = 100, .nice = 0, .system = 100, .idle = 500, .iowait = 0, .irq = 0, .softirq = 0, .steal = 0};
    QCOMPARE(computeCpuUsagePercent(prev, resetJiffies), 0);

    // Zero delta: curr == prev
    QCOMPARE(computeCpuUsagePercent(prev, prev), 0);
}

void tst_SystemUsage::testParseFrequencyMHzValues() {
    const auto frequency = parseFrequencyMHz("4200000\n");
    QVERIFY(frequency.has_value());
    QCOMPARE(*frequency, 4200);

    const auto lowFrequency = parseFrequencyMHz("800000\n");
    QVERIFY(lowFrequency.has_value());
    QCOMPARE(*lowFrequency, 800);

    QVERIFY(!parseFrequencyMHz("").has_value());
    QVERIFY(!parseFrequencyMHz("abc").has_value());
}

void tst_SystemUsage::testCoreFrequencyPathsNumericOrdering() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    for (const auto coreId : {2, 10}) {
        const QString directory = sysRoot.path() + u"/devices/system/cpu/cpu" + QString::number(coreId) + u"/cpufreq";
        QVERIFY(QDir().mkpath(directory));
        QFile file(directory + u"/scaling_cur_freq");
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Text));
        file.write("2000000\n");
    }

    SensorScanner scanner(sysRoot.path());
    scanner.scan();
    QCOMPARE(scanner.coreFrequencyPaths().size(), 2);
    QCOMPARE(scanner.coreFrequencyPaths().at(0).coreId, 2);
    QCOMPARE(scanner.coreFrequencyPaths().at(1).coreId, 10);
}

void tst_SystemUsage::testNonContiguousCpuCores() {
    // Offline cores: cpu0, cpu1, cpu4, cpu5 (cores 2 and 3 offline)
    const QByteArray      stat = "cpu  1000 0 1000 8000 0 0 0 0 0 0\n"
                                 "cpu0 250 0 250 2000 0 0 0 0 0 0\n"
                                 "cpu1 250 0 250 2000 0 0 0 0 0 0\n"
                                 "cpu4 250 0 250 2000 0 0 0 0 0 0\n"
                                 "cpu5 250 0 250 2000 0 0 0 0 0 0\n";

    const CpuStatSnapshot snap = parseCpuStat(stat);
    QVERIFY(snap.valid);
    QCOMPARE(snap.perCore.size(), 4);
    QVERIFY(snap.perCore.contains(0));
    QVERIFY(snap.perCore.contains(1));
    QVERIFY(!snap.perCore.contains(2));
    QVERIFY(!snap.perCore.contains(3));
    QVERIFY(snap.perCore.contains(4));
    QVERIFY(snap.perCore.contains(5));
}

void tst_SystemUsage::testSensorScannerIntelAmdAndMissing() {
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());
    const QString sysRoot = tempDir.path();

    // 1. Missing hwmon
    SensorScanner missingScanner(sysRoot);
    missingScanner.scan();
    QVERIFY(!missingScanner.readCpuTemperature().has_value());
    QVERIFY(!missingScanner.readGpuTemperature().has_value());
    QVERIFY(!missingScanner.readBatteryTemperature().has_value());
    QVERIFY(missingScanner.readBatteryTechnology().isEmpty());

    // 2. Intel coretemp
    const QString intelHwmon = sysRoot + u"/class/hwmon/hwmon0";
    QVERIFY(QDir().mkpath(intelHwmon));
    QVERIFY(writeSysfsFile(tempDir, u"class/hwmon/hwmon0/name", "coretemp\n"));
    QVERIFY(writeSysfsFile(tempDir, u"class/hwmon/hwmon0/temp1_label", "Package id 0\n"));
    QVERIFY(writeSysfsFile(tempDir, u"class/hwmon/hwmon0/temp1_input", "54000\n"));

    SensorScanner intelScanner(sysRoot);
    intelScanner.scan();
    const auto intelTemperature = intelScanner.readCpuTemperature();
    QVERIFY(intelTemperature.has_value());
    QCOMPARE(*intelTemperature, 54.0);

    // 3. AMD k10temp with Tdie + Tctl
    QTemporaryDir amdTempDir;
    QVERIFY(amdTempDir.isValid());
    const QString amdSysRoot = amdTempDir.path();
    const QString amdHwmon   = amdSysRoot + u"/class/hwmon/hwmon0";
    QVERIFY(QDir().mkpath(amdHwmon));
    QVERIFY(writeSysfsFile(amdTempDir, u"class/hwmon/hwmon0/name", "k10temp\n"));
    QVERIFY(writeSysfsFile(amdTempDir, u"class/hwmon/hwmon0/temp1_label", "Tctl\n"));
    QVERIFY(writeSysfsFile(amdTempDir, u"class/hwmon/hwmon0/temp1_input", "65000\n"));
    QVERIFY(writeSysfsFile(amdTempDir, u"class/hwmon/hwmon0/temp2_label", "Tdie\n"));
    QVERIFY(writeSysfsFile(amdTempDir, u"class/hwmon/hwmon0/temp2_input", "62500\n"));

    SensorScanner amdScanner(amdSysRoot);
    amdScanner.scan();
    // Prefers Tdie (62.5°C) over Tctl (65.0°C)
    const auto amdTemperature = amdScanner.readCpuTemperature();
    QVERIFY(amdTemperature.has_value());
    QCOMPARE(*amdTemperature, 62.5);
}

void tst_SystemUsage::testFilesystemDeduplication() {
    const std::vector<FilesystemRawEntry> rawEntries = {
        {
            .deviceName     = QStringLiteral("/dev/nvme0n1p2"),
            .filesystemType = QStringLiteral("ext4"),
            .mountPoint     = QStringLiteral("/"),
            .usedKiB        = 50000000,
            .freeKiB        = 50000000,
            .totalKiB       = 100000000,
        },
        {
            // Bind mount for the same device with identical size
            .deviceName     = QStringLiteral("/dev/nvme0n1p2"),
            .filesystemType = QStringLiteral("ext4"),
            .mountPoint     = QStringLiteral("/nix/store"),
            .usedKiB        = 50000000,
            .freeKiB        = 50000000,
            .totalKiB       = 100000000,
        },
        {
            // Boot mount
            .deviceName     = QStringLiteral("/dev/nvme0n1p1"),
            .filesystemType = QStringLiteral("vfat"),
            .mountPoint     = QStringLiteral("/boot/efi"),
            .usedKiB        = 100000,
            .freeKiB        = 400000,
            .totalKiB       = 500000,
        },
        {
            // USB disk first entry with smaller size
            .deviceName     = QStringLiteral("/dev/sda1"),
            .filesystemType = QStringLiteral("btrfs"),
            .mountPoint     = QStringLiteral("/run/media/sub"),
            .usedKiB        = 10000,
            .freeKiB        = 20000,
            .totalKiB       = 30000,
        },
        {
            // USB disk second entry with larger size (should replace)
            .deviceName     = QStringLiteral("/dev/sda1"),
            .filesystemType = QStringLiteral("btrfs"),
            .mountPoint     = QStringLiteral("/run/media/main"),
            .usedKiB        = 500000,
            .freeKiB        = 1500000,
            .totalKiB       = 2000000,
        },
    };

    const StorageSummary summary = deduplicateFilesystems(rawEntries);

    // Exactly 3 unique block devices
    QCOMPARE(summary.filesystems.size(), 3);

    // Verify /dev/sda1 took the 2,000,000 KiB entry
    bool foundSda1 = false;
    for (const auto& fs : summary.filesystems) {
        if (fs.deviceName == u"/dev/sda1") {
            foundSda1 = true;
            QCOMPARE(fs.totalKiB, 2000000ULL);
            QCOMPARE(fs.mountPoint, QStringLiteral("/run/media/main"));
        }
    }
    QVERIFY(foundSda1);

    // Verify totals are not double counted
    // /dev/nvme0n1p2: 100,000,000 KiB total, 50,000,000 KiB used, 50,000,000 KiB free
    // /dev/nvme0n1p1: 500,000 KiB total, 100,000 KiB used, 400,000 KiB free (system)
    // /dev/sda1: 2,000,000 KiB total, 500,000 KiB used, 1,500,000 KiB free
    QCOMPARE(summary.totalKiB, 102500000ULL);
    QCOMPARE(summary.totalUsedKiB, 50600000ULL);
    QCOMPARE(summary.totalFreeKiB, 51900000ULL);

    // System usedKiB includes /boot/efi (100,000)
    QCOMPARE(summary.systemUsedKiB, 100000ULL);
    // Apps usedKiB includes root (50,000,000) + sda1 (500,000)
    QCOMPARE(summary.appsUsedKiB, 50500000ULL);
}

void tst_SystemUsage::testFilesystemDeduplicationUsedPercentDerived() {
    const std::vector<FilesystemRawEntry> rawEntries = {
        {
            .deviceName     = QStringLiteral("/dev/sda1"),
            .filesystemType = QStringLiteral("ext4"),
            .mountPoint     = QStringLiteral("/"),
            .usedKiB        = 2500,
            .freeKiB        = 7500,
            .totalKiB       = 10000,
        },
        {
            .deviceName     = QStringLiteral("/dev/sdb1"),
            .filesystemType = QStringLiteral("ext4"),
            .mountPoint     = QStringLiteral("/mnt/zero"),
            .usedKiB        = 0,
            .freeKiB        = 0,
            .totalKiB       = 0,
        },
    };

    const StorageSummary summary = deduplicateFilesystems(rawEntries);
    QCOMPARE(summary.filesystems.size(), 2);
    for (const auto& fs : summary.filesystems) {
        if (fs.totalKiB > 0) {
            const double expected = (static_cast<double>(fs.usedKiB) * 100.0) / static_cast<double>(fs.totalKiB);
            QCOMPARE(fs.usedPercent, expected);
        } else {
            QCOMPARE(fs.usedPercent, 0.0);
        }
    }
}

void tst_SystemUsage::testNetDevParsingAndReset() {
    const QByteArray netdev = "Inter-|   Receive                                                |  Transmit\n"
                              " face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n"
                              "    lo: 1000000    1000    0    0    0     0          0         0  1000000    1000    0    0    0     0       0          0\n"
                              "enp0s31f6: 50000000    5000    0    0    0     0          0         0 20000000    3000    0    0    0     0       0          0\n"
                              "wlp3s0: 80000000    8000    0    0    0     0          0         0 40000000    4000    0    0    0     0       0          0\n"
                              "   wg0: 5000000     500    0    0    0     0          0         0  5000000     500    0    0    0     0       0          0\n";

    const auto       counters = parseNetDev(netdev);
    QCOMPARE(counters.size(), 4);
    QVERIFY(counters.contains(QStringLiteral("enp0s31f6")));
    QVERIFY(counters.contains(QStringLiteral("wlp3s0")));
    QVERIFY(counters.contains(QStringLiteral("wg0")));

    QCOMPARE(counters.value(QStringLiteral("wlp3s0")).rxBytes, 80000000ULL);
    QCOMPARE(counters.value(QStringLiteral("wlp3s0")).txBytes, 40000000ULL);

    // Speed computation: 1 MiB in 1 second -> 1.0 MB/s
    const double speed = computeNetSpeedMiBps(1048576, 2097152, 1.0);
    QCOMPARE(speed, 1.0);

    // Counter reset: current < previous -> 0.0
    QCOMPARE(computeNetSpeedMiBps(2000000, 1000000, 1.0), 0.0);

    // Elapsed <= 0.1 -> 0.0
    QCOMPARE(computeNetSpeedMiBps(1000000, 2000000, 0.05), 0.0);
}

void tst_SystemUsage::testCpuCoresModelIncrementalSignals() {
    CpuCoresModel             model;
    QSignalSpy                countSpy(&model, &CpuCoresModel::countChanged);
    QSignalSpy                dataChangedSpy(&model, &CpuCoresModel::dataChanged);
    QSignalSpy                modelResetSpy(&model, &CpuCoresModel::modelReset);

    std::vector<CpuCoreEntry> initialCores;
    for (int coreId = 0; coreId < 8; ++coreId) {
        initialCores.push_back({.coreId = coreId, .freqMHz = 2400, .usagePercent = 10});
    }

    model.updateCores(initialCores);
    QCOMPARE(countSpy.count(), 1);
    QCOMPARE(modelResetSpy.count(), 1);
    QCOMPARE(model.count(), 8);

    countSpy.clear();
    dataChangedSpy.clear();
    modelResetSpy.clear();

    // 1. Update identical data -> 0 signals
    model.updateCores(initialCores);
    QCOMPARE(countSpy.count(), 0);
    QCOMPARE(modelResetSpy.count(), 0);
    QCOMPARE(dataChangedSpy.count(), 0);

    // 2. Update 1 core only (core 3 frequency changed to 3200 MHz)
    auto modifiedCores       = initialCores;
    modifiedCores[3].freqMHz = 3200;

    model.updateCores(modifiedCores);
    QCOMPARE(countSpy.count(), 0);
    QCOMPARE(modelResetSpy.count(), 0);
    QCOMPARE(dataChangedSpy.count(), 1);

    const auto arguments   = dataChangedSpy.takeFirst();
    const auto topLeft     = arguments.at(0).toModelIndex();
    const auto bottomRight = arguments.at(1).toModelIndex();
    QCOMPARE(topLeft.row(), 3);
    QCOMPARE(bottomRight.row(), 3);
}

void tst_SystemUsage::testFilesystemsModelIncrementalSignals() {
    FilesystemsModel             model;
    QSignalSpy                   countSpy(&model, &FilesystemsModel::countChanged);
    QSignalSpy                   dataChangedSpy(&model, &FilesystemsModel::dataChanged);
    QSignalSpy                   modelResetSpy(&model, &FilesystemsModel::modelReset);

    FilesystemEntry              firstEntry{FilesystemRawEntry{
                                                .deviceName     = QStringLiteral("/dev/nvme0n1p2"),
                                                .filesystemType = QStringLiteral("ext4"),
                                                .mountPoint     = QStringLiteral("/"),
                                                .usedKiB        = 40000000,
                                                .freeKiB        = 60000000,
                                                .totalKiB       = 100000000,
                               },
                               40.0};

    FilesystemEntry              secondEntry{FilesystemRawEntry{
                                                 .deviceName     = QStringLiteral("/dev/sda1"),
                                                 .filesystemType = QStringLiteral("btrfs"),
                                                 .mountPoint     = QStringLiteral("/media/data"),
                                                 .usedKiB        = 10000000,
                                                 .freeKiB        = 90000000,
                                                 .totalKiB       = 100000000,
                                },
                                10.0};

    std::vector<FilesystemEntry> initialEntries{firstEntry, secondEntry};

    model.updateFilesystems(initialEntries);
    QCOMPARE(countSpy.count(), 1);
    QCOMPARE(modelResetSpy.count(), 1);
    QCOMPARE(model.count(), 2);

    countSpy.clear();
    dataChangedSpy.clear();
    modelResetSpy.clear();

    // 1. Update identical entries -> 0 signals
    model.updateFilesystems(initialEntries);
    QCOMPARE(countSpy.count(), 0);
    QCOMPARE(modelResetSpy.count(), 0);
    QCOMPARE(dataChangedSpy.count(), 0);

    // 2. Update entry 1 only
    auto modifiedEntries           = initialEntries;
    modifiedEntries[1].usedKiB     = 15000000;
    modifiedEntries[1].freeKiB     = 85000000;
    modifiedEntries[1].usedPercent = 15.0;

    model.updateFilesystems(modifiedEntries);
    QCOMPARE(countSpy.count(), 0);
    QCOMPARE(modelResetSpy.count(), 0);
    QCOMPARE(dataChangedSpy.count(), 1);

    const auto arguments = dataChangedSpy.takeFirst();
    const auto topLeft   = arguments.at(0).toModelIndex();
    QCOMPARE(topLeft.row(), 1);
}

void tst_SystemUsage::testFilesystemsModelResetsWhenDeviceSetChanges() {
    FilesystemsModel             model;
    QSignalSpy                   countSpy(&model, &FilesystemsModel::countChanged);
    QSignalSpy                   dataChangedSpy(&model, &FilesystemsModel::dataChanged);
    QSignalSpy                   modelResetSpy(&model, &FilesystemsModel::modelReset);

    FilesystemEntry              firstEntry{FilesystemRawEntry{
                                                .deviceName     = QStringLiteral("/dev/sda1"),
                                                .filesystemType = QStringLiteral("ext4"),
                                                .mountPoint     = QStringLiteral("/"),
                                                .usedKiB        = 500,
                                                .freeKiB        = 500,
                                                .totalKiB       = 1000,
                               },
                               50.0};
    std::vector<FilesystemEntry> entriesA{firstEntry};

    model.updateFilesystems(entriesA);
    QCOMPARE(modelResetSpy.count(), 1);
    countSpy.clear();
    dataChangedSpy.clear();
    modelResetSpy.clear();

    FilesystemEntry              replacedEntry{FilesystemRawEntry{
                                                   .deviceName     = QStringLiteral("/dev/sdb1"),
                                                   .filesystemType = QStringLiteral("ext4"),
                                                   .mountPoint     = QStringLiteral("/"),
                                                   .usedKiB        = 500,
                                                   .freeKiB        = 500,
                                                   .totalKiB       = 1000,
                                  },
                                  50.0};
    std::vector<FilesystemEntry> entriesB{replacedEntry};

    // Same count (1), but deviceName changed from sda1 to sdb1: must reset, not emit dataChanged
    model.updateFilesystems(entriesB);
    QCOMPARE(modelResetSpy.count(), 1);
    QCOMPARE(countSpy.count(), 1);
    QCOMPARE(dataChangedSpy.count(), 0);
}

void tst_SystemUsage::testFormatters() {
    QCOMPARE(formatKiB(512), QStringLiteral("512 KiB"));
    QCOMPARE(formatKiB(1048576), QStringLiteral("1.00 GiB"));
    QCOMPARE(formatKiB(524288), QStringLiteral("512.00 MiB"));

    QCOMPARE(formatUsageMiB(0.5), QStringLiteral("512.00 KiB"));
    QCOMPARE(formatUsageMiB(256.0), QStringLiteral("256.00 MiB"));
    QCOMPARE(formatUsageMiB(2048.0), QStringLiteral("2.00 GiB"));

    QCOMPARE(formatSpeedMiBps(0.0), QStringLiteral("0.00 KiB/s"));
    QCOMPARE(formatSpeedMiBps(0.005), QStringLiteral("5.12 KiB/s"));
    QCOMPARE(formatSpeedMiBps(0.5), QStringLiteral("512.00 KiB/s"));
    QCOMPARE(formatSpeedMiBps(2.5), QStringLiteral("2.50 MiB/s"));

    QCOMPARE(formatUptime(45), QStringLiteral("0m"));
    QCOMPARE(formatUptime(125), QStringLiteral("2m"));
    QCOMPARE(formatUptime(7320), QStringLiteral("2h 2m"));
    QCOMPARE(formatUptime(90000), QStringLiteral("1d 1h 0m"));
}

void tst_SystemUsage::testOsReleaseAndCpuInfoParsers() {
    const QByteArray osRelease = "NAME=\"NixOS\"\n"
                                 "ID=nixos\n"
                                 "ID_LIKE=\"arch\"\n"
                                 "PRETTY_NAME=\"NixOS 25.05 (Warbler)\"\n";

    const auto       os = parseOsRelease(osRelease);
    QCOMPARE(os.name, QStringLiteral("NixOS"));
    QCOMPARE(os.id, QStringLiteral("nixos"));
    QCOMPARE(os.idLike, QStringLiteral("arch"));
    QCOMPARE(os.prettyName, QStringLiteral("NixOS 25.05 (Warbler)"));

    const QByteArray cpuinfo = "processor\t: 0\n"
                               "vendor_id\t: GenuineIntel\n"
                               "model name\t: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz\n"
                               "stepping\t: 9\n";

    const QString    cpuName = parseCpuModelName(cpuinfo);
    QCOMPARE(cpuName, QStringLiteral("Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz"));
}

void tst_SystemUsage::testUdevPciGpuParser() {
    const QByteArray udevData = "E:ID_PCI_CLASS_FROM_DATABASE=Display controller\n"
                                "E:ID_VENDOR_FROM_DATABASE=Intel Corporation\n"
                                "E:ID_MODEL_FROM_DATABASE=Kaby Lake-U GT2 [HD Graphics 620]\n";

    const QString    gpuName = parseUdevPciGpuName(udevData);
    QCOMPARE(gpuName, QStringLiteral("Intel Corporation Kaby Lake-U GT2 [HD Graphics 620]"));

    const QByteArray udevDataVendorInModel = "E:ID_VENDOR_FROM_DATABASE=AMD\n"
                                             "E:ID_MODEL_FROM_DATABASE=AMD Radeon RX 6700 XT\n";
    const QString    gpuNameAmd            = parseUdevPciGpuName(udevDataVendorInModel);
    QCOMPARE(gpuNameAmd, QStringLiteral("AMD Radeon RX 6700 XT"));
}

void tst_SystemUsage::testParseCpuStatMalformed() {
    const QByteArray      stat     = "cpu  1000 0 1000 8000 0 0 0 0 0 0\n"
                                     "cpu0 250 0 250\n"
                                     "cpu1 250 0 250 2000 0 0 0 0 0 0\n";
    const CpuStatSnapshot snapshot = parseCpuStat(stat);
    QVERIFY(snapshot.valid);
    QVERIFY(!snapshot.perCore.contains(0));
    QVERIFY(snapshot.perCore.contains(1));

    const QByteArray      badStat     = "cpu  abc 0 1000 8000 0 0 0 0 0 0\n"
                                        "cpu0 250 0 250 2000 0 0 0 0 0 0\n";
    const CpuStatSnapshot badSnapshot = parseCpuStat(badStat);
    QVERIFY(!badSnapshot.valid);
    QVERIFY(badSnapshot.perCore.contains(0));

    const QByteArray      extraStat     = "cpu  1000 0 1000 8000 0 0 0 0 0 0 999 888\n";
    const CpuStatSnapshot extraSnapshot = parseCpuStat(extraStat);
    QVERIFY(extraSnapshot.valid);
    QCOMPARE(extraSnapshot.aggregate.user, 1000ULL);

    const QByteArray      wrapped = "cpu  5 0 5 10 0 0 0 0 0 0\n";
    const CpuStatSnapshot before  = parseCpuStat("cpu  18446744073709551615 0 0 0 0 0 0 0 0 0\n");
    const CpuStatSnapshot after   = parseCpuStat(wrapped);
    QCOMPARE(computeCpuUsagePercent(before.aggregate, after.aggregate), 0);

    const QByteArray overflowStat = "cpu  99999999999999999999999999 0 0 0 0 0 0 0 0 0\n";
    QVERIFY(!parseCpuStat(overflowStat).valid);
}

void tst_SystemUsage::testParseMemInfoMalformed() {
    // Missing MemAvailable: falls back to MemFree + Buffers + Cached
    const MemInfoSnapshot missingAvailable = parseMemInfo("MemTotal: 2048 kB\nMemFree: 256 kB\nBuffers: 64 kB\nCached: 128 kB\n");
    QVERIFY(missingAvailable.valid);
    QCOMPARE(missingAvailable.totalKiB, 2048ULL);
    QCOMPARE(missingAvailable.availableKiB, 448ULL);
    QCOMPARE(missingAvailable.usedKiB, 1600ULL);

    // Total only, no usable availability: invalid
    const MemInfoSnapshot totalOnly = parseMemInfo("MemTotal: 2048 kB\n");
    QVERIFY(!totalOnly.valid);

    // Empty input: invalid
    QVERIFY(!parseMemInfo("").valid);

    // Overflow: invalid
    const MemInfoSnapshot overflow = parseMemInfo("MemTotal: 99999999999999999999999999 kB\n");
    QVERIFY(!overflow.valid);
}

void tst_SystemUsage::testParseNetDevMalformed() {
    const QByteArray netdev   = " header line one\n"
                                " header line two\n"
                                "no-colon-here\n"
                                "eth0: abc\n"
                                "wlan0: 1000 1 0 0 0 0 0 0 2000 1 0 0 0 0 0 0\n";
    const auto       counters = parseNetDev(netdev);
    QCOMPARE(counters.size(), 1);
    QVERIFY(counters.contains(QStringLiteral("wlan0")));
    QCOMPARE(counters.value(QStringLiteral("wlan0")).rxBytes, 1000ULL);
    QCOMPARE(counters.value(QStringLiteral("wlan0")).txBytes, 2000ULL);

    const QByteArray spaced         = " h1\n"
                                      " h2\n"
                                      "    eth9 : 7 0 0 0 0 0 0 0 9 0 0 0 0 0 0 0\n";
    const auto       spacedCounters = parseNetDev(spaced);
    QCOMPARE(spacedCounters.size(), 1);
    QVERIFY(spacedCounters.contains(QStringLiteral("eth9")));
}

void tst_SystemUsage::testParseOsReleaseMalformed() {
    const auto empty = parseOsRelease("");
    QVERIFY(empty.name.isEmpty());
    QVERIFY(empty.id.isEmpty());
    QVERIFY(empty.prettyName.isEmpty());

    const auto partial = parseOsRelease("ID=arch\nPRETTY_NAME=\"Arch Linux\"\n");
    QCOMPARE(partial.id, QStringLiteral("arch"));
    QCOMPARE(partial.prettyName, QStringLiteral("Arch Linux"));
    QVERIFY(partial.name.isEmpty());
}

void tst_SystemUsage::testParseUdevPciGpuNameMalformed() {
    QVERIFY(parseUdevPciGpuName("").isEmpty());
    QCOMPARE(parseUdevPciGpuName("E:ID_VENDOR_FROM_DATABASE=AMD\n"), QStringLiteral("AMD"));
    QCOMPARE(parseUdevPciGpuName("E:ID_MODEL_FROM_DATABASE=Radeon RX 6700 XT\n"), QStringLiteral("Radeon RX 6700 XT"));
}

void tst_SystemUsage::testParseGraphicsOutputs() {
    const GraphicsSummary emptySummary = parseGraphicsOutputs("", "", "");
    QVERIFY(!emptySummary.vulkanAvailable);
    QVERIFY(!emptySummary.openglAvailable);
    QVERIFY(emptySummary.vaApiDriver.isEmpty());

    const GraphicsSummary garbageSummary = parseGraphicsOutputs("garbage\n", "not a renderer\n", "nothing here\n");
    QVERIFY(!garbageSummary.vulkanAvailable);
    QVERIFY(!garbageSummary.openglAvailable);

    const GraphicsSummary vulkanSummary = parseGraphicsOutputs("Vulkan Instance Version: 1.3.280\n", "", "");
    QVERIFY(vulkanSummary.vulkanAvailable);
    QCOMPARE(vulkanSummary.vulkanVersion, QStringLiteral("1.3.280"));

    const GraphicsSummary openglSummary = parseGraphicsOutputs("", "OpenGL vendor string: NVIDIA\nOpenGL renderer string: RTX 4070\nOpenGL version string: 4.6.0\n", "");
    QVERIFY(openglSummary.openglAvailable);
    QCOMPARE(openglSummary.openglVendor, QStringLiteral("NVIDIA"));
    QCOMPARE(openglSummary.openglRenderer, QStringLiteral("RTX 4070"));
    QCOMPARE(openglSummary.openglVersion, QStringLiteral("4.6.0"));

    const GraphicsSummary vaSummary = parseGraphicsOutputs("", "", "Driver version: 24.1.8\n");
    QCOMPARE(vaSummary.vaApiDriver, QStringLiteral("24.1.8"));
}

void tst_SystemUsage::testGraphicsProbeSuccess() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.3.280'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"),
                          "printf 'OpenGL vendor string: NVIDIA\\nOpenGL renderer string: RTX 4070\\nOpenGL version string: 4.6.0\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"), "printf 'OpenGL vendor string: glx\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 24.1.8'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(summary.vulkanAvailable);
    QCOMPARE(summary.vulkanVersion, QStringLiteral("1.3.280"));
    QVERIFY(summary.openglAvailable);
    QCOMPARE(summary.openglVendor, QStringLiteral("NVIDIA"));
    QCOMPARE(summary.openglRenderer, QStringLiteral("RTX 4070"));
    QCOMPARE(summary.openglVersion, QStringLiteral("4.6.0"));
    QCOMPARE(summary.vaApiDriver, QStringLiteral("24.1.8"));
}

void tst_SystemUsage::testGraphicsProbeToolsMissing() {
    FakeToolPath      fakePath;

    GraphicsInfoProbe probe(nullptr, 500, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(!summary.vulkanAvailable);
    QVERIFY(!summary.openglAvailable);
    QVERIFY(summary.vaApiDriver.isEmpty());
}

void tst_SystemUsage::testGraphicsProbeToolCrash() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "kill -9 $$\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "printf 'OpenGL vendor string: crash-eglinfo\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 24.1.8'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(!summary.vulkanAvailable);
    QCOMPARE(summary.vaApiDriver, QStringLiteral("24.1.8"));
}

void tst_SystemUsage::testGraphicsProbeToolNonZeroExit() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "exit 1\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "printf 'OpenGL vendor string: nonzero-eglinfo\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 24.1.8'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(!summary.vulkanAvailable);
    QCOMPARE(summary.vaApiDriver, QStringLiteral("24.1.8"));
}

void tst_SystemUsage::testGraphicsProbeToolHangs() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "while :; do :; done\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"), "printf 'OpenGL vendor string: timeout-glx\\nOpenGL renderer string: fallback\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: hang-test'\n"));

    GraphicsInfoProbe probe(nullptr, 400, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(!summary.vulkanAvailable);
    QCOMPARE(summary.vaApiDriver, QStringLiteral("hang-test"));
}

void tst_SystemUsage::testGraphicsProbeEglinfoEmptyFallsBackToGlxinfo() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.4.0'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "exit 0\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"),
                          "printf 'OpenGL vendor string: Mesa\\nOpenGL renderer string: llvmpipe\\nOpenGL version string: 4.5.0\\n'\n"
                          "echo launched >> " +
                              fakePath.toolDirectory.path().toUtf8() + "/glxinfo-launches\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 25.0'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QCOMPARE(summary.openglVendor, QStringLiteral("Mesa"));
    QCOMPARE(summary.openglRenderer, QStringLiteral("llvmpipe"));

    QFile launches(fakePath.toolDirectory.path() + u"/glxinfo-launches");
    QVERIFY(launches.open(QIODevice::ReadOnly | QIODevice::Text));
    QCOMPARE(launches.readAll().count("launched"), 1);
}

void tst_SystemUsage::testGraphicsProbeEglinfoFailsFallsBackToGlxinfo() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.4.0'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "exit 1\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"),
                          "printf 'OpenGL vendor string: MesaFallback\\n'\n"
                          "echo launched >> " +
                              fakePath.toolDirectory.path().toUtf8() + "/glxinfo-launches\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 25.0'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QCOMPARE(summary.openglVendor, QStringLiteral("MesaFallback"));

    QFile launches(fakePath.toolDirectory.path() + u"/glxinfo-launches");
    QVERIFY(launches.open(QIODevice::ReadOnly | QIODevice::Text));
    QCOMPARE(launches.readAll().count("launched"), 1);
}

void tst_SystemUsage::testGraphicsProbeNoDriDeviceGoesStraightToGlxinfo() {
    FakeToolPath fakePath;
    // Do NOT create DRI node; driDirectory has no renderD* or card* nodes
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.4.0'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "echo launched-egl >> " + fakePath.toolDirectory.path().toUtf8() + "/eglinfo-launches\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"),
                          "printf 'OpenGL vendor string: PureGlx\\n'\n"
                          "echo launched-glx >> " +
                              fakePath.toolDirectory.path().toUtf8() + "/glxinfo-launches\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 25.0'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QCOMPARE(summary.openglVendor, QStringLiteral("PureGlx"));

    QVERIFY(!QFile::exists(fakePath.toolDirectory.path() + u"/eglinfo-launches"));
    QFile glxLaunches(fakePath.toolDirectory.path() + u"/glxinfo-launches");
    QVERIFY(glxLaunches.open(QIODevice::ReadOnly | QIODevice::Text));
    QCOMPARE(glxLaunches.readAll().count("launched-glx"), 1);
}

void tst_SystemUsage::testGraphicsProbeNonZeroExitWithOutputVulkanAndGlxinfo() {
    FakeToolPath fakePath;
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.3.99'\nexit 1\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("glxinfo"), "printf 'OpenGL vendor string: GlxErrorVendor\\n'\nexit 2\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 1.2.3'\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QVERIFY(summary.vulkanAvailable);
    QCOMPARE(summary.vulkanVersion, QStringLiteral("1.3.99"));
    QCOMPARE(summary.openglVendor, QStringLiteral("GlxErrorVendor"));
}

void tst_SystemUsage::testGraphicsProbeVaApiNonzeroExitWithOutput() {
    FakeToolPath fakePath;
    QVERIFY(fakePath.createFakeDriNode());
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vulkaninfo"), "echo 'Vulkan Instance Version: 1.3.100'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("eglinfo"), "printf 'OpenGL vendor string: NANOVENDOR\\n'\n"));
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("vainfo"), "echo 'Driver version: 9.9.9'\nexit 3\n"));

    GraphicsInfoProbe probe(nullptr, 2000, fakePath.driDirectory.path());
    QSignalSpy        spy(&probe, &GraphicsInfoProbe::finished);

    probe.startProbe();
    QTRY_VERIFY(spy.count() == 1);

    const auto summary = qvariant_cast<GraphicsSummary>(spy.at(0).at(0));
    QCOMPARE(summary.vaApiDriver, QStringLiteral("9.9.9"));
}

void tst_SystemUsage::testGraphicsProbeFinishedAlwaysAsync() {
    FakeToolPath      fakePath;
    GraphicsInfoProbe probe(nullptr, 500, fakePath.driDirectory.path());

    probe.startProbe();
    QSignalSpy spy(&probe, &GraphicsInfoProbe::finished);
    QTRY_VERIFY(spy.count() == 1);
    QVERIFY(probe.isLoaded());
}

void tst_SystemUsage::testSensorScannerTctlBeatsGeneric() {
    // acpitz (usually hwmon0) must not shadow a Tctl-only k10temp (hwmon1)
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/name", "acpitz\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/temp1_label", "temp1\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon0/temp1_input", "99000\n"));
    QVERIFY(QDir().mkpath(sysRoot.path() + u"/class/hwmon/hwmon1"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon1/name", "k10temp\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon1/temp2_label", "Tctl\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/hwmon/hwmon1/temp2_input", "61000\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.scan();
    const auto temperature = scanner.readCpuTemperature();
    QVERIFY(temperature.has_value());
    QCOMPARE(*temperature, 61.0);
}

void tst_SystemUsage::testSensorScannerIntelPackageAfterCores() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSensorFixture(
        sysRoot, QStringLiteral("coretemp"),
        {{QStringLiteral("Core 0"), QStringLiteral("45000")}, {QStringLiteral("Core 1"), QStringLiteral("46000")}, {QStringLiteral("Package id 0"), QStringLiteral("55000")}}));

    SensorScanner scanner(sysRoot.path());
    scanner.scan();
    const auto temperature = scanner.readCpuTemperature();
    QVERIFY(temperature.has_value());
    QCOMPARE(*temperature, 55.0);
}

void tst_SystemUsage::testSensorScannerTemperatureSanityRange() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSensorFixture(sysRoot, QStringLiteral("coretemp"), {{QStringLiteral("Package id 0"), QStringLiteral("250000")}}));

    SensorScanner scanner(sysRoot.path());
    scanner.scan();
    QVERIFY(!scanner.readCpuTemperature().has_value());
}

void tst_SystemUsage::testSensorScannerNegativeTemperatureAccepted() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSensorFixture(sysRoot, QStringLiteral("coretemp"), {{QStringLiteral("Package id 0"), QStringLiteral("-10000")}}));

    SensorScanner scanner(sysRoot.path());
    scanner.scan();
    const auto temperature = scanner.readCpuTemperature();
    QVERIFY(temperature.has_value());
    QCOMPARE(*temperature, -10.0);
}

void tst_SystemUsage::testSensorScannerVpnNameClassification() {
    const QList<QString> names = {QStringLiteral("lo"),    QStringLiteral("tun0"),  QStringLiteral("tap0"), QStringLiteral("wg0"),
                                  QStringLiteral("tunl0"), QStringLiteral("vnet0"), QStringLiteral("sit0")};

    QTemporaryDir        sysRoot;
    QVERIFY(sysRoot.isValid());
    for (const auto& name : names)
        QVERIFY(writeSysfsFile(sysRoot, u"class/net/" + name + u"/operstate", "up\n"));

    SensorScanner scanner(sysRoot.path());
    for (const auto& name : names) {
        scanner.updateInterfaces({name});
        const QString status = scanner.detectVpnStatus();
        if (name == u"tun0" || name == u"tap0" || name == u"wg0") {
            QCOMPARE(status, QStringLiteral("connected"));
        } else {
            QCOMPARE(status, QStringLiteral("disconnected"));
        }
    }
}

void tst_SystemUsage::testSensorScannerVpnWireguardCustomName() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/mullvad-us1/uevent", "DEVTYPE=wireguard\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/mullvad-us1/operstate", "unknown\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("lo"), QStringLiteral("mullvad-us1")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));

    QVERIFY(writeSysfsFile(sysRoot, u"class/net/mullvad-us1/operstate", "down\n"));
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("disconnected"));
}

void tst_SystemUsage::testSensorScannerVpnOperstateFlip() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/tun0/operstate", "up\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("lo"), QStringLiteral("tun0")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));

    QVERIFY(writeSysfsFile(sysRoot, u"class/net/tun0/operstate", "unknown\n"));
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));

    QVERIFY(writeSysfsFile(sysRoot, u"class/net/tun0/operstate", "down\n"));
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("disconnected"));

    QVERIFY(writeSysfsFile(sysRoot, u"class/net/tun0/operstate", "up\n"));
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));
}

void tst_SystemUsage::testSensorScannerInterfaceAppearDisappear() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/wg0/operstate", "up\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("lo")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("disconnected"));

    scanner.updateInterfaces({QStringLiteral("lo"), QStringLiteral("wg0")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));

    scanner.updateInterfaces({QStringLiteral("lo")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("disconnected"));
}

void tst_SystemUsage::testSensorScannerWirelessReplug() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/wlp3s0/wireless", ""));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("lo"), QStringLiteral("wlp3s0")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral("wlp3s0"));

    // Adapter unplugged: directory vanished from the interface list and from sysfs
    QDir(sysRoot.path() + u"/class/net/wlp3s0").removeRecursively();
    scanner.updateInterfaces({QStringLiteral("lo")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral(""));

    QVERIFY(writeSysfsFile(sysRoot, u"class/net/wlp4s0/wireless", ""));
    scanner.updateInterfaces({QStringLiteral("lo"), QStringLiteral("wlp4s0")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral("wlp4s0"));
}

void tst_SystemUsage::testSensorScannerWiredOnlyInterfaceCache() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/eth0/operstate", "up\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("eth0")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral(""));

    // Mutate sysfs on disk: create wireless file without calling updateInterfaces
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/wlp2s0/wireless", ""));
    // Negative result must be cached; detectWirelessInterface must NOT re-read sysfs
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral(""));

    // Updating with identical interface set also does not invalidate the cache
    scanner.updateInterfaces({QStringLiteral("eth0")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral(""));

    // When the new interface is reported through updateInterfaces, cache is invalidated
    scanner.updateInterfaces({QStringLiteral("eth0"), QStringLiteral("wlp2s0")});
    QCOMPARE(scanner.detectWirelessInterface(), QStringLiteral("wlp2s0"));
}

void tst_SystemUsage::testSensorScannerUnorderedInterfacesNoRescan() {
    QTemporaryDir sysRoot;
    QVERIFY(sysRoot.isValid());
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/custom-wg/uevent", "DEVTYPE=wireguard\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/custom-wg/operstate", "up\n"));
    QVERIFY(writeSysfsFile(sysRoot, u"class/net/eth0/operstate", "up\n"));

    SensorScanner scanner(sysRoot.path());
    scanner.updateInterfaces({QStringLiteral("eth0"), QStringLiteral("custom-wg")});
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));

    // Delete uevent file on disk so that re-evaluating refreshVpnCandidates would fail to identify it as WireGuard
    QFile::remove(sysRoot.path() + u"/class/net/custom-wg/uevent");

    // Call updateInterfaces with identical names in reverse order
    scanner.updateInterfaces({QStringLiteral("custom-wg"), QStringLiteral("eth0")});

    // Caching based on sorted names prevents re-evaluating candidates; status remains connected
    QCOMPARE(scanner.detectVpnStatus(), QStringLiteral("connected"));
}

void tst_SystemUsage::testParseLspciGpuName() {
    const QByteArray vgaOutput = "00:02.0 VGA compatible controller: Intel Corporation Kaby Lake-U GT2 [HD Graphics 620] (rev 04)\n"
                                 "00:14.0 USB controller: Intel Corporation Sunrise Point-LP USB 3.0 xHCI Controller (rev 21)\n";
    QCOMPARE(parseLspciGpuName(vgaOutput), QStringLiteral("Intel Corporation Kaby Lake-U GT2 [HD Graphics 620] (rev 04)"));

    QVERIFY(parseLspciGpuName("").isEmpty());
    QVERIFY(parseLspciGpuName("00:14.0 USB controller: Intel Corporation Sunrise Point-LP USB 3.0\n").isEmpty());
}

void tst_SystemUsage::testParseFrequencyMHzMalformed() {
    const auto frequency = parseFrequencyMHz("  4200000\n");
    QVERIFY(frequency.has_value());
    QCOMPARE(*frequency, 4200);
    QVERIFY(!parseFrequencyMHz("").has_value());
    QVERIFY(!parseFrequencyMHz("abc").has_value());
    QVERIFY(!parseFrequencyMHz("99999999999999999999999999").has_value());
}

void tst_SystemUsage::testWirelessBitrateSuccess() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    QTRY_VERIFY(spy.count() == 1);
    QCOMPARE(spy.at(0).at(0).toString(), QStringLiteral("wlan0"));
    QCOMPARE(spy.at(0).at(1).toInt(), 576);
}

void tst_SystemUsage::testWirelessBitrateEmptyPath() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("empty-path"));
    QTRY_VERIFY(spy.count() == 1);
    QCOMPARE(spy.at(0).at(1).toInt(), 0);
}

void tst_SystemUsage::testWirelessBitrateUnknownInterface() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("no-such-interface"));
    QTRY_VERIFY(spy.count() == 1);
    QCOMPARE(spy.at(0).at(1).toInt(), 0);
}

void tst_SystemUsage::testWirelessBitrateDBusError() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("error-iface"));
    QTRY_VERIFY(spy.count() == 1);
    QCOMPARE(spy.at(0).at(1).toInt(), 0);
}

void tst_SystemUsage::testWirelessBitratePropertyErrorAndStalePath() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("ghost"));
    QTRY_VERIFY(spy.count() == 1);
    QCOMPARE(spy.at(0).at(1).toInt(), 0);

    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    QTRY_VERIFY(spy.count() == 2);
    QCOMPARE(spy.at(1).at(1).toInt(), 576);

    // Stale path error
    mBus->unregisterObject(QStringLiteral("/org/freedesktop/NetworkManager/Devices/42"));
    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    QTRY_VERIFY(spy.count() == 3);
    QCOMPARE(spy.at(2).at(1).toInt(), 0);

    // Re-register device: next request re-resolves path from scratch and resolves successfully
    mBus->registerObject(QStringLiteral("/org/freedesktop/NetworkManager/Devices/42"), &fakeBus.device,
                         QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllInvokables | QDBusConnection::ExportAllProperties |
                             QDBusConnection::ExportScriptableProperties);
    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    QTRY_VERIFY(spy.count() == 4);
    QCOMPARE(spy.at(3).at(1).toInt(), 576);
}

void tst_SystemUsage::testWirelessBitrateConcurrentRequestIgnored() {
    REQUIRE_BUS();
    FakeBus fakeBus(*mBus);
    fakeBus.setup();

    WirelessBitrateReader reader(nullptr, *mBus, mBus->baseService());
    QSignalSpy            spy(&reader, &WirelessBitrateReader::bitrateResolved);

    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    reader.requestBitrateMbps(QStringLiteral("wlan0"));
    QTRY_VERIFY(spy.count() >= 1);
    QTest::qWait(50);
    QCOMPARE(spy.count(), 1);
}

void tst_SystemUsage::testSystemUsageMonitorNetworkUnplug() {
    QTemporaryDir tempDir;
    QVERIFY(tempDir.isValid());
    const QString    netdevPath = tempDir.path() + u"/netdev";

    const QByteArray initialNetdev = "Inter-|   Receive                                                |  Transmit\n"
                                     " face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n"
                                     "  eth0: 10000000 1000 0 0 0 0 0 0 20000000 2000 0 0 0 0 0 0\n"
                                     " wlan0: 30000000 3000 0 0 0 0 0 0 40000000 4000 0 0 0 0 0 0\n";
    QVERIFY(writeSysfsFile(tempDir, u"netdev", initialNetdev));
    QVERIFY(writeSysfsFile(tempDir, u"class/net/wlan0/wireless", ""));

    SystemUsageMonitor monitor(nullptr, netdevPath, QStringLiteral("lspci"), tempDir.path());
    monitor.setWiredInterface(QStringLiteral("eth0"));
    monitor.sampleNow();

    QCOMPARE(monitor.wirelessInterface(), QStringLiteral("wlan0"));

    // 1. Wireless adapter unplugged: missing from netdev
    const QByteArray wiredOnlyNetdev = "Inter-|   Receive                                                |  Transmit\n"
                                       " face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n"
                                       "  eth0: 10000000 1000 0 0 0 0 0 0 20000000 2000 0 0 0 0 0 0\n";
    QVERIFY(writeSysfsFile(tempDir, u"netdev", wiredOnlyNetdev));
    monitor.sampleNow();

    QCOMPARE(monitor.wirelessInterface(), QStringLiteral(""));
    QCOMPARE(monitor.wirelessLinkSpeed(), 0);
    QCOMPARE(monitor.wirelessDownloadSpeed(), 0.0);
    QCOMPARE(monitor.wirelessUploadSpeed(), 0.0);

    // 2. Wired adapter unplugged: missing from netdev
    const QByteArray emptyCountersNetdev = "Inter-|   Receive                                                |  Transmit\n"
                                           " face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed\n";
    QVERIFY(writeSysfsFile(tempDir, u"netdev", emptyCountersNetdev));
    monitor.sampleNow();

    QCOMPARE(monitor.wiredDownloadSpeed(), 0.0);
    QCOMPARE(monitor.wiredUploadSpeed(), 0.0);

    // 3. netdev unreadable/empty: resets both and sets vpn disconnected
    QVERIFY(writeSysfsFile(tempDir, u"netdev", ""));
    monitor.sampleNow();

    QCOMPARE(monitor.statusVPNInterface(), QStringLiteral("disconnected"));
}

void tst_SystemUsage::testSystemUsageMonitorLspci() {
    FakeToolPath fakePath;
    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("fake_lspci"), "echo '00:02.0 VGA compatible controller: Custom Mock GPU [9999] (rev 01)'\n"));
    {
        SystemUsageMonitor monitor(nullptr, QStringLiteral("/proc/net/dev"), fakePath.toolDirectory.path() + u"/fake_lspci");
        QSignalSpy         spy(&monitor, &SystemUsageMonitor::gpuNameChanged);
        monitor.detectGpuNameFromLspciAsync();
        QTRY_VERIFY(spy.count() >= 1);
        QCOMPARE(monitor.gpuName(), QStringLiteral("Custom Mock GPU [9999] (rev 01)"));
    }

    QVERIFY(writeFakeTool(fakePath.toolDirectory, QStringLiteral("hang_lspci"), "while :; do :; done\n"));
    {
        SystemUsageMonitor monitor(nullptr, QStringLiteral("/proc/net/dev"), fakePath.toolDirectory.path() + u"/hang_lspci");
        monitor.detectGpuNameFromLspciAsync();
        QTest::qWait(1100);
    }

    {
        SystemUsageMonitor monitor(nullptr, QStringLiteral("/proc/net/dev"), QStringLiteral("/nonexistent/lspci"));
        monitor.detectGpuNameFromLspciAsync();
        QTest::qWait(50);
    }
}

QTEST_MAIN(tst_SystemUsage)
#include "tst_systemusage.moc"
