#include "SystemStatParsers.hpp"

#include <qalgorithms.h>
#include <qchar.h>
#include <qlist.h>
#include <qstringview.h>

#include <algorithm>
#include <cmath>
#include <string_view>

namespace vast::sysusage {

    namespace {

        [[nodiscard]] std::string_view toStringView(QByteArrayView byteView) noexcept {
            return {byteView.data(), static_cast<size_t>(byteView.size())};
        }

        [[nodiscard]] QString cleanQuotedValue(QStringView text) {
            auto trimmed = text.trimmed();
            if (trimmed.size() >= 2 && ((trimmed.startsWith(u'"') && trimmed.endsWith(u'"')) || (trimmed.startsWith(u'\'') && trimmed.endsWith(u'\'')))) {
                trimmed = trimmed.mid(1, trimmed.size() - 2);
            }
            return trimmed.toString();
        }

        [[nodiscard]] std::optional<CpuJiffies> parseJiffiesLine(std::string_view line) noexcept {
            CpuJiffies jiffies;
            size_t     offset = 0;

            // Skip cpu label
            while (offset < line.size() && !std::isspace(static_cast<unsigned char>(line[offset]))) {
                ++offset;
            }

            const std::array<quint64*, 8> destinations = {&jiffies.user,   &jiffies.nice, &jiffies.system,  &jiffies.idle,
                                                          &jiffies.iowait, &jiffies.irq,  &jiffies.softirq, &jiffies.steal};
            for (quint64* destination : destinations) {
                while (offset < line.size() && std::isspace(static_cast<unsigned char>(line[offset]))) {
                    ++offset;
                }
                if (offset >= line.size())
                    return std::nullopt;

                quint64 value      = 0;
                size_t  digitCount = 0;
                while (offset < line.size() && std::isdigit(static_cast<unsigned char>(line[offset]))) {
                    value = value * 10 + static_cast<quint64>(line[offset] - '0');
                    ++offset;
                    ++digitCount;
                }
                if (digitCount == 0)
                    return std::nullopt;
                *destination = value;
            }

            return jiffies;
        }

    } // namespace

    CpuStatSnapshot parseCpuStat(QByteArrayView content) {
        CpuStatSnapshot        snapshot;
        const std::string_view text      = toStringView(content);
        size_t                 lineStart = 0;

        while (lineStart < text.size()) {
            size_t lineEnd = text.find('\n', lineStart);
            if (lineEnd == std::string_view::npos)
                lineEnd = text.size();

            const std::string_view line = text.substr(lineStart, lineEnd - lineStart);
            lineStart                   = lineEnd + 1;

            if (line.starts_with("cpu ")) {
                if (auto jiffies = parseJiffiesLine(line)) {
                    snapshot.aggregate = *jiffies;
                    snapshot.valid     = true;
                }
            } else if (line.starts_with("cpu")) {
                size_t offset = 3;
                int    coreId = 0;
                size_t digits = 0;
                while (offset < line.size() && std::isdigit(static_cast<unsigned char>(line[offset]))) {
                    coreId = coreId * 10 + (line[offset] - '0');
                    ++offset;
                    ++digits;
                }
                if (digits > 0 && offset < line.size() && std::isspace(static_cast<unsigned char>(line[offset]))) {
                    if (auto jiffies = parseJiffiesLine(line)) {
                        snapshot.perCore.insert(coreId, *jiffies);
                    }
                }
            }
        }

        return snapshot;
    }

    int computeCpuUsagePercent(const CpuJiffies& previous, const CpuJiffies& current) noexcept {
        const quint64 previousTotal = previous.total();
        const quint64 currentTotal  = current.total();
        if (currentTotal <= previousTotal)
            return 0;

        const quint64 totalDelta   = currentTotal - previousTotal;
        const quint64 previousIdle = previous.idleAll();
        const quint64 currentIdle  = current.idleAll();
        const quint64 idleDelta    = (currentIdle > previousIdle) ? (currentIdle - previousIdle) : 0;

        if (idleDelta >= totalDelta)
            return 0;
        const quint64 activeDelta = totalDelta - idleDelta;

        const double  percent = (static_cast<double>(activeDelta) * 100.0) / static_cast<double>(totalDelta);
        return std::clamp(static_cast<int>(std::round(percent)), 0, 100);
    }

    std::optional<std::pair<int, int>> parseCoreFrequency(QStringView sysfsPath, QByteArrayView content) noexcept {
        static constexpr QStringView pattern        = u"/cpu";
        qsizetype                    searchPosition = 0;
        int                          coreId         = -1;

        while (searchPosition < sysfsPath.size()) {
            const qsizetype matchIndex = sysfsPath.indexOf(pattern, searchPosition);
            if (matchIndex < 0)
                break;

            qsizetype offset     = matchIndex + pattern.size();
            int       currentId  = 0;
            qsizetype digitCount = 0;
            while (offset < sysfsPath.size() && sysfsPath[offset].isDigit()) {
                currentId = currentId * 10 + sysfsPath[offset].digitValue();
                ++offset;
                ++digitCount;
            }
            if (digitCount > 0) {
                coreId = currentId;
                break;
            }
            searchPosition = matchIndex + pattern.size();
        }

        if (coreId < 0)
            return std::nullopt;
        const std::string_view text       = toStringView(content);
        size_t                 textOffset = 0;
        while (textOffset < text.size() && std::isspace(static_cast<unsigned char>(text[textOffset]))) {
            ++textOffset;
        }

        quint64 frequencyKhz = 0;
        size_t  valueDigits  = 0;
        while (textOffset < text.size() && std::isdigit(static_cast<unsigned char>(text[textOffset]))) {
            frequencyKhz = frequencyKhz * 10 + static_cast<quint64>(text[textOffset] - '0');
            ++textOffset;
            ++valueDigits;
        }
        if (valueDigits == 0)
            return std::nullopt;

        const int frequencyMHz = static_cast<int>(frequencyKhz / 1000);
        return std::make_pair(coreId, frequencyMHz);
    }

    MemInfoSnapshot parseMemInfo(QByteArrayView content) noexcept {
        MemInfoSnapshot        snapshot;
        const std::string_view text      = toStringView(content);
        size_t                 lineStart = 0;

        auto                   parseKbValue = [](std::string_view line) -> quint64 {
            const size_t colon = line.find(':');
            if (colon == std::string_view::npos)
                return 0;
            size_t offset = colon + 1;
            while (offset < line.size() && std::isspace(static_cast<unsigned char>(line[offset]))) {
                ++offset;
            }
            quint64 value = 0;
            while (offset < line.size() && std::isdigit(static_cast<unsigned char>(line[offset]))) {
                value = value * 10 + static_cast<quint64>(line[offset] - '0');
                ++offset;
            }
            return value;
        };

        while (lineStart < text.size()) {
            size_t lineEnd = text.find('\n', lineStart);
            if (lineEnd == std::string_view::npos)
                lineEnd = text.size();

            const std::string_view line = text.substr(lineStart, lineEnd - lineStart);
            lineStart                   = lineEnd + 1;

            if (line.starts_with("MemTotal:")) {
                snapshot.totalKiB = parseKbValue(line);
            } else if (line.starts_with("MemAvailable:")) {
                snapshot.availableKiB = parseKbValue(line);
            }
        }

        if (snapshot.totalKiB > 0) {
            snapshot.valid = true;
            if (snapshot.totalKiB >= snapshot.availableKiB) {
                snapshot.usedKiB = snapshot.totalKiB - snapshot.availableKiB;
            }
        }

        return snapshot;
    }

    std::optional<quint64> parseUptimeSeconds(QByteArrayView content) noexcept {
        const std::string_view text   = toStringView(content);
        size_t                 offset = 0;
        while (offset < text.size() && std::isspace(static_cast<unsigned char>(text[offset]))) {
            ++offset;
        }
        if (offset >= text.size() || !std::isdigit(static_cast<unsigned char>(text[offset]))) {
            return std::nullopt;
        }

        quint64 integerPart = 0;
        while (offset < text.size() && std::isdigit(static_cast<unsigned char>(text[offset]))) {
            integerPart = integerPart * 10 + static_cast<quint64>(text[offset] - '0');
            ++offset;
        }

        return integerPart;
    }

    QHash<QString, NetInterfaceCounters> parseNetDev(QByteArrayView content) {
        QHash<QString, NetInterfaceCounters> result;
        const std::string_view               text      = toStringView(content);
        size_t                               lineStart = 0;
        size_t                               lineIndex = 0;

        while (lineStart < text.size()) {
            size_t lineEnd = text.find('\n', lineStart);
            if (lineEnd == std::string_view::npos)
                lineEnd = text.size();

            const std::string_view line = text.substr(lineStart, lineEnd - lineStart);
            lineStart                   = lineEnd + 1;
            ++lineIndex;

            if (lineIndex <= 2)
                continue; // Skip header lines

            const size_t colon = line.find(':');
            if (colon == std::string_view::npos)
                continue;

            // Extract interface name
            size_t nameStart = 0;
            while (nameStart < colon && std::isspace(static_cast<unsigned char>(line[nameStart]))) {
                ++nameStart;
            }
            size_t nameEnd = colon;
            while (nameEnd > nameStart && std::isspace(static_cast<unsigned char>(line[nameEnd - 1]))) {
                --nameEnd;
            }
            if (nameStart >= nameEnd)
                continue;

            const auto    sub           = line.substr(nameStart, nameEnd - nameStart);
            const QString interfaceName = QString::fromUtf8(sub.data(), static_cast<qsizetype>(sub.size()));

            // Parse numbers after colon: token 0 is rxBytes, token 8 is txBytes
            size_t               offset = colon + 1;
            NetInterfaceCounters counters;
            bool                 rxFound = false;

            for (int tokenIndex = 0; tokenIndex < 16; ++tokenIndex) {
                while (offset < line.size() && std::isspace(static_cast<unsigned char>(line[offset]))) {
                    ++offset;
                }
                if (offset >= line.size())
                    break;

                quint64 value      = 0;
                size_t  digitCount = 0;
                while (offset < line.size() && std::isdigit(static_cast<unsigned char>(line[offset]))) {
                    value = value * 10 + static_cast<quint64>(line[offset] - '0');
                    ++offset;
                    ++digitCount;
                }
                if (digitCount == 0)
                    break;

                if (tokenIndex == 0) {
                    counters.rxBytes = value;
                    rxFound          = true;
                } else if (tokenIndex == 8) {
                    counters.txBytes = value;
                    break;
                }
            }

            if (rxFound) {
                result.insert(interfaceName, counters);
            }
        }

        return result;
    }

    double computeNetSpeedMBps(quint64 previousBytes, quint64 currentBytes, double elapsedSeconds) noexcept {
        if (currentBytes < previousBytes || elapsedSeconds <= 0.1)
            return 0.0;
        const quint64 byteDelta   = currentBytes - previousBytes;
        const double  bytesPerSec = static_cast<double>(byteDelta) / elapsedSeconds;
        return bytesPerSec / 1048576.0;
    }

    StorageSummary deduplicateFilesystems(std::span<const FilesystemRawEntry> entries) {
        StorageSummary                 summary;
        QMap<QString, FilesystemEntry> deduplicated;

        for (const auto& rawEntry : entries) {
            if (rawEntry.deviceName.isEmpty())
                continue;

            const double          percent = rawEntry.totalKiB > 0 ? (static_cast<double>(rawEntry.usedKiB) * 100.0 / static_cast<double>(rawEntry.totalKiB)) : 0.0;

            const FilesystemEntry entry{
                .deviceName     = rawEntry.deviceName,
                .filesystemType = rawEntry.filesystemType,
                .mountPoint     = rawEntry.mountPoint,
                .usedKiB        = rawEntry.usedKiB,
                .freeKiB        = rawEntry.freeKiB,
                .totalKiB       = rawEntry.totalKiB,
                .usedPercent    = percent,
            };

            auto existingIterator = deduplicated.find(entry.deviceName);
            if (existingIterator == deduplicated.end()) {
                deduplicated.insert(entry.deviceName, entry);
            } else {
                // If device already registered, keep the one with larger total capacity or root mount
                if (entry.totalKiB > existingIterator->totalKiB || (entry.totalKiB == existingIterator->totalKiB && entry.mountPoint == u"/")) {
                    *existingIterator = entry;
                }
            }
        }

        summary.filesystems.reserve(deduplicated.size());
        for (const auto& entry : deduplicated) {
            summary.filesystems.append(entry);
            summary.totalUsedKiB += entry.usedKiB;
            summary.totalFreeKiB += entry.freeKiB;
            summary.totalKiB += entry.totalKiB;

            const bool isSystemMount = entry.mountPoint == u"/nix" || entry.mountPoint == u"/nix/store" || entry.mountPoint == u"/boot" || entry.mountPoint == u"/boot/efi" ||
                entry.mountPoint.startsWith(u"/boot/");
            if (isSystemMount) {
                summary.systemUsedKiB += entry.usedKiB;
            } else {
                summary.appsUsedKiB += entry.usedKiB;
            }
        }

        return summary;
    }

    OsReleaseInfo parseOsRelease(QByteArrayView content) {
        OsReleaseInfo info;
        const QString text  = QString::fromUtf8(content.data(), content.size());
        const auto    lines = QStringView(text).split(u'\n');

        for (const auto& line : lines) {
            const qsizetype equalIndex = line.indexOf(u'=');
            if (equalIndex < 0)
                continue;

            const auto key   = line.left(equalIndex).trimmed();
            const auto value = line.mid(equalIndex + 1);

            if (key == u"PRETTY_NAME") {
                info.prettyName = cleanQuotedValue(value);
            } else if (key == u"NAME") {
                info.name = cleanQuotedValue(value);
            } else if (key == u"ID") {
                info.id = cleanQuotedValue(value);
            } else if (key == u"ID_LIKE") {
                info.idLike = cleanQuotedValue(value);
            }
        }

        return info;
    }

    QString parseCpuModelName(QByteArrayView cpuinfoContent) {
        const QString text  = QString::fromUtf8(cpuinfoContent.data(), cpuinfoContent.size());
        const auto    lines = QStringView(text).split(u'\n');

        for (const auto& line : lines) {
            const qsizetype colonIndex = line.indexOf(u':');
            if (colonIndex < 0)
                continue;

            const auto key = line.left(colonIndex).trimmed();
            if (key == u"model name" || key == u"Model" || key == u"Hardware" || key == u"Processor") {
                return line.mid(colonIndex + 1).trimmed().toString();
            }
        }

        return {};
    }

    QString parseUdevPciGpuName(QByteArrayView udevDataContent) {
        const QString text  = QString::fromUtf8(udevDataContent.data(), udevDataContent.size());
        const auto    lines = QStringView(text).split(u'\n');

        QString       vendor;
        QString       model;

        for (const auto& line : lines) {
            if (line.startsWith(u"E:ID_MODEL_FROM_DATABASE=")) {
                model = line.mid(25).trimmed().toString();
            } else if (line.startsWith(u"E:ID_VENDOR_FROM_DATABASE=")) {
                vendor = line.mid(26).trimmed().toString();
            }
        }

        if (model.isEmpty())
            return vendor;
        if (vendor.isEmpty() || model.startsWith(vendor, Qt::CaseInsensitive)) {
            return model;
        }

        return vendor + u' ' + model;
    }

    GraphicsSummary parseGraphicsOutputs(QByteArrayView vulkanOutput, QByteArrayView openglOutput, QByteArrayView vaApiOutput) {
        GraphicsSummary summary;

        // Parse Vulkan
        const QString vulkanText  = QString::fromUtf8(vulkanOutput.data(), vulkanOutput.size());
        const auto    vulkanLines = QStringView(vulkanText).split(u'\n');
        for (const auto& line : vulkanLines) {
            if (line.contains(u"Vulkan Instance Version:", Qt::CaseInsensitive)) {
                summary.vulkanAvailable = true;
                const qsizetype colon   = line.indexOf(u':');
                if (colon >= 0) {
                    summary.vulkanVersion = line.mid(colon + 1).trimmed().toString();
                }
            } else if (line.contains(u"deviceName", Qt::CaseInsensitive) && !summary.vulkanAvailable) {
                summary.vulkanAvailable = true;
            }
        }

        // Parse OpenGL (eglinfo or glxinfo)
        const QString openglText  = QString::fromUtf8(openglOutput.data(), openglOutput.size());
        const auto    openglLines = QStringView(openglText).split(u'\n');
        for (const auto& line : openglLines) {
            if (line.contains(u"OpenGL vendor string:", Qt::CaseInsensitive)) {
                summary.openglAvailable = true;
                const qsizetype colon   = line.indexOf(u':');
                if (colon >= 0)
                    summary.openglVendor = line.mid(colon + 1).trimmed().toString();
            } else if (line.contains(u"OpenGL renderer string:", Qt::CaseInsensitive)) {
                summary.openglAvailable = true;
                const qsizetype colon   = line.indexOf(u':');
                if (colon >= 0)
                    summary.openglRenderer = line.mid(colon + 1).trimmed().toString();
            } else if (line.contains(u"OpenGL core profile version string:", Qt::CaseInsensitive) ||
                       (summary.openglVersion.isEmpty() && line.contains(u"OpenGL version string:", Qt::CaseInsensitive))) {
                summary.openglAvailable = true;
                const qsizetype colon   = line.indexOf(u':');
                if (colon >= 0)
                    summary.openglVersion = line.mid(colon + 1).trimmed().toString();
            }
        }

        // Parse VA-API
        const QString vaApiText  = QString::fromUtf8(vaApiOutput.data(), vaApiOutput.size());
        const auto    vaApiLines = QStringView(vaApiText).split(u'\n');
        for (const auto& line : vaApiLines) {
            if (line.contains(u"Driver version:", Qt::CaseInsensitive)) {
                const qsizetype colon = line.indexOf(u':');
                if (colon >= 0) {
                    summary.vaApiDriver = line.mid(colon + 1).trimmed().toString();
                    break;
                }
            }
        }

        return summary;
    }

} // namespace vast::sysusage
