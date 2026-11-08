#pragma once

#include <qbytearray.h>
#include <qbytearrayview.h>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qlist.h>
#include <qmap.h>
#include <qstring.h>
#include <qstringview.h>
#include <qtypes.h>

#include <cmath>
#include <optional>
#include <span>
#include <utility>

namespace vast::sysusage {

    struct CpuJiffies {
        quint64                         user{0};
        quint64                         nice{0};
        quint64                         system{0};
        quint64                         idle{0};
        quint64                         iowait{0};
        quint64                         irq{0};
        quint64                         softirq{0};
        quint64                         steal{0};

        [[nodiscard]] constexpr quint64 total() const noexcept {
            return user + nice + system + idle + iowait + irq + softirq + steal;
        }

        [[nodiscard]] constexpr quint64 idleAll() const noexcept {
            return idle + iowait;
        }

        auto operator<=>(const CpuJiffies&) const noexcept = default;
    };

    struct CpuStatSnapshot {
        bool                  valid{false};
        CpuJiffies            aggregate;
        QMap<int, CpuJiffies> perCore;
    };

    struct MemInfoSnapshot {
        bool    valid{false};
        quint64 totalKiB{0};
        quint64 availableKiB{0};
        quint64 usedKiB{0};
    };

    struct NetInterfaceCounters {
        quint64 rxBytes{0};
        quint64 txBytes{0};

        auto    operator<=>(const NetInterfaceCounters&) const noexcept = default;
    };

    struct FilesystemRawEntry {
        QString deviceName;
        QString filesystemType;
        QString mountPoint;
        quint64 usedKiB{0};
        quint64 freeKiB{0};
        quint64 totalKiB{0};
    };

    struct FilesystemEntry {
        QString            deviceName;
        QString            filesystemType;
        QString            mountPoint;
        quint64            usedKiB{0};
        quint64            freeKiB{0};
        quint64            totalKiB{0};
        double             usedPercent{0.0};

        [[nodiscard]] bool operator==(const FilesystemEntry& other) const noexcept {
            return deviceName == other.deviceName && filesystemType == other.filesystemType && mountPoint == other.mountPoint && usedKiB == other.usedKiB &&
                freeKiB == other.freeKiB && totalKiB == other.totalKiB && std::abs(usedPercent - other.usedPercent) < 0.0001;
        }
    };

    struct StorageSummary {
        QList<FilesystemEntry> filesystems;
        quint64                totalUsedKiB{0};
        quint64                totalFreeKiB{0};
        quint64                totalKiB{0};
        quint64                appsUsedKiB{0};
        quint64                systemUsedKiB{0};
    };

    struct OsReleaseInfo {
        QString prettyName;
        QString name;
        QString id;
        QString idLike;
    };

    struct GraphicsSummary {
        bool    vulkanAvailable{false};
        QString vulkanVersion;
        bool    openglAvailable{false};
        QString openglVersion;
        QString openglVendor;
        QString openglRenderer;
        QString vaApiDriver;
    };

    [[nodiscard]] CpuStatSnapshot                      parseCpuStat(QByteArrayView content);
    [[nodiscard]] int                                  computeCpuUsagePercent(const CpuJiffies& previous, const CpuJiffies& current) noexcept;
    [[nodiscard]] std::optional<std::pair<int, int>>   parseCoreFrequency(QStringView sysfsPath, QByteArrayView content) noexcept;
    [[nodiscard]] MemInfoSnapshot                      parseMemInfo(QByteArrayView content) noexcept;
    [[nodiscard]] std::optional<quint64>               parseUptimeSeconds(QByteArrayView content) noexcept;
    [[nodiscard]] QHash<QString, NetInterfaceCounters> parseNetDev(QByteArrayView content);
    [[nodiscard]] double                               computeNetSpeedMBps(quint64 previousBytes, quint64 currentBytes, double elapsedSeconds) noexcept;
    [[nodiscard]] StorageSummary                       deduplicateFilesystems(std::span<const FilesystemRawEntry> entries);
    [[nodiscard]] OsReleaseInfo                        parseOsRelease(QByteArrayView content);
    [[nodiscard]] QString                              parseCpuModelName(QByteArrayView cpuinfoContent);
    [[nodiscard]] QString                              parseUdevPciGpuName(QByteArrayView udevDataContent);
    [[nodiscard]] GraphicsSummary                      parseGraphicsOutputs(QByteArrayView vulkanOutput, QByteArrayView openglOutput, QByteArrayView vaApiOutput);

} // namespace vast::sysusage
