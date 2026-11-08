#include "../../SystemUsage/CpuCoresModel.hpp"
#include "../../SystemUsage/FilesystemsModel.hpp"
#include "../../SystemUsage/SensorScanner.hpp"
#include "../../SystemUsage/SystemFormatters.hpp"
#include "../../SystemUsage/SystemStatParsers.hpp"

#include <qbytearray.h>
#include <qdir.h>
#include <qfile.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtemporarydir.h>
#include <qtest.h>

using namespace vast;
using namespace vast::sysusage;

class tst_SystemUsage : public QObject {
    Q_OBJECT

  private slots:
    void testMemInfo64BitOverflow();
    void testCpuStatJiffiesOverflow();
    void testCpuJiffiesCompletenessAndReset();
    void testPerCoreFrequencyParsingAndOrdering();
    void testNonContiguousCpuCores();
    void testSensorScannerIntelAmdAndMissing();
    void testFilesystemDeduplication();
    void testNetDevParsingAndReset();
    void testCpuCoresModelIncrementalSignals();
    void testFilesystemsModelIncrementalSignals();
    void testFormatters();
    void testOsReleaseAndCpuInfoParsers();
    void testUdevPciGpuParser();
};

void tst_SystemUsage::testMemInfo64BitOverflow() {
    const QByteArray      meminfo = "MemTotal:        67108864 kB\n"
                                    "MemFree:         33554432 kB\n"
                                    "MemAvailable:    50331648 kB\n";

    const MemInfoSnapshot snapshot = parseMemInfo(meminfo);
    QVERIFY(snapshot.valid);
    QCOMPARE(snapshot.totalKiB, 67108864ULL);
    QCOMPARE(snapshot.availableKiB, 50331648ULL);
    QCOMPARE(snapshot.usedKiB, 16777216ULL);

    QCOMPARE(formatKiB(snapshot.totalKiB), QStringLiteral("64.00 GB"));
    QCOMPARE(formatKiB(snapshot.usedKiB), QStringLiteral("16.00 GB"));

    // 4 TiB memory test
    const QByteArray      hugeMeminfo  = "MemTotal:        4294967296 kB\n"
                                         "MemAvailable:    2147483648 kB\n";
    const MemInfoSnapshot hugeSnapshot = parseMemInfo(hugeMeminfo);
    QVERIFY(hugeSnapshot.valid);
    QCOMPARE(hugeSnapshot.totalKiB, 4294967296ULL);
    QCOMPARE(hugeSnapshot.usedKiB, 2147483648ULL);
    QCOMPARE(formatKiB(hugeSnapshot.totalKiB), QStringLiteral("4096.00 GB"));
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

void tst_SystemUsage::testPerCoreFrequencyParsingAndOrdering() {
    // Lexicographical ordering vs numeric core ID
    const auto core2  = parseCoreFrequency(u"/sys/devices/system/cpu/cpu2/cpufreq/scaling_cur_freq", "4200000\n");
    const auto core10 = parseCoreFrequency(u"/sys/devices/system/cpu/cpu10/cpufreq/scaling_cur_freq", "800000\n");

    QVERIFY(core2.has_value());
    QCOMPARE(core2->first, 2);
    QCOMPARE(core2->second, 4200);

    QVERIFY(core10.has_value());
    QCOMPARE(core10->first, 10);
    QCOMPARE(core10->second, 800);
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
    QCOMPARE(missingScanner.readCpuTemperature(), 0.0);
    QCOMPARE(missingScanner.readGpuTemperature(), 0.0);
    QCOMPARE(missingScanner.readBatteryTemperature(), 0.0);
    QVERIFY(missingScanner.readBatteryTechnology().isEmpty());

    // 2. Intel coretemp
    const QString intelHwmon = sysRoot + u"/class/hwmon/hwmon0";
    QDir().mkpath(intelHwmon);
    {
        QFile nameFile(intelHwmon + u"/name");
        QVERIFY(nameFile.open(QIODevice::WriteOnly | QIODevice::Text));
        nameFile.write("coretemp\n");
    }
    {
        QFile labelFile(intelHwmon + u"/temp1_label");
        QVERIFY(labelFile.open(QIODevice::WriteOnly | QIODevice::Text));
        labelFile.write("Package id 0\n");
    }
    {
        QFile inputFile(intelHwmon + u"/temp1_input");
        QVERIFY(inputFile.open(QIODevice::WriteOnly | QIODevice::Text));
        inputFile.write("54000\n");
    }

    SensorScanner intelScanner(sysRoot);
    intelScanner.scan();
    QCOMPARE(intelScanner.readCpuTemperature(), 54.0);

    // 3. AMD k10temp with Tdie + Tctl
    QTemporaryDir amdTempDir;
    QVERIFY(amdTempDir.isValid());
    const QString amdSysRoot = amdTempDir.path();
    const QString amdHwmon   = amdSysRoot + u"/class/hwmon/hwmon0";
    QDir().mkpath(amdHwmon);
    {
        QFile nameFile(amdHwmon + u"/name");
        QVERIFY(nameFile.open(QIODevice::WriteOnly | QIODevice::Text));
        nameFile.write("k10temp\n");
    }
    {
        QFile labelFile1(amdHwmon + u"/temp1_label");
        QVERIFY(labelFile1.open(QIODevice::WriteOnly | QIODevice::Text));
        labelFile1.write("Tctl\n");
    }
    {
        QFile inputFile1(amdHwmon + u"/temp1_input");
        QVERIFY(inputFile1.open(QIODevice::WriteOnly | QIODevice::Text));
        inputFile1.write("65000\n");
    }
    {
        QFile labelFile2(amdHwmon + u"/temp2_label");
        QVERIFY(labelFile2.open(QIODevice::WriteOnly | QIODevice::Text));
        labelFile2.write("Tdie\n");
    }
    {
        QFile inputFile2(amdHwmon + u"/temp2_input");
        QVERIFY(inputFile2.open(QIODevice::WriteOnly | QIODevice::Text));
        inputFile2.write("62500\n");
    }

    SensorScanner amdScanner(amdSysRoot);
    amdScanner.scan();
    // Prefers Tdie (62.5°C) over Tctl (65.0°C)
    QCOMPARE(amdScanner.readCpuTemperature(), 62.5);
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
    const double speed = computeNetSpeedMBps(1048576, 2097152, 1.0);
    QCOMPARE(speed, 1.0);

    // Counter reset: current < previous -> 0.0
    QCOMPARE(computeNetSpeedMBps(2000000, 1000000, 1.0), 0.0);

    // Elapsed <= 0.1 -> 0.0
    QCOMPARE(computeNetSpeedMBps(1000000, 2000000, 0.05), 0.0);
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

    std::vector<FilesystemEntry> initialEntries = {
        {
            .deviceName     = QStringLiteral("/dev/nvme0n1p2"),
            .filesystemType = QStringLiteral("ext4"),
            .mountPoint     = QStringLiteral("/"),
            .usedKiB        = 40000000,
            .freeKiB        = 60000000,
            .totalKiB       = 100000000,
            .usedPercent    = 40.0,
        },
        {
            .deviceName     = QStringLiteral("/dev/sda1"),
            .filesystemType = QStringLiteral("btrfs"),
            .mountPoint     = QStringLiteral("/media/data"),
            .usedKiB        = 10000000,
            .freeKiB        = 90000000,
            .totalKiB       = 100000000,
            .usedPercent    = 10.0,
        },
    };

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

void tst_SystemUsage::testFormatters() {
    // formatKiB
    QCOMPARE(formatKiB(512), QStringLiteral("512 KB"));
    QCOMPARE(formatKiB(1048576), QStringLiteral("1.00 GB"));
    QCOMPARE(formatKiB(524288), QStringLiteral("512.00 MB"));

    // formatUsageMiB
    QCOMPARE(formatUsageMiB(0.5), QStringLiteral("512.00 KB"));
    QCOMPARE(formatUsageMiB(256.0), QStringLiteral("256.00 MB"));
    QCOMPARE(formatUsageMiB(2048.0), QStringLiteral("2.00 GB"));

    // formatSpeedMBps
    QCOMPARE(formatSpeedMBps(0.005), QStringLiteral("0.00 MB/s"));
    QCOMPARE(formatSpeedMBps(0.5), QStringLiteral("512.00 KB/s"));
    QCOMPARE(formatSpeedMBps(2.5), QStringLiteral("2.50 MB/s"));

    // formatUptime
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

    // Vendor already in model string
    const QByteArray udevDataVendorInModel = "E:ID_VENDOR_FROM_DATABASE=AMD\n"
                                             "E:ID_MODEL_FROM_DATABASE=AMD Radeon RX 6700 XT\n";
    const QString    gpuNameAmd            = parseUdevPciGpuName(udevDataVendorInModel);
    QCOMPARE(gpuNameAmd, QStringLiteral("AMD Radeon RX 6700 XT"));
}

QTEST_MAIN(tst_SystemUsage)
#include "tst_systemusage.moc"
