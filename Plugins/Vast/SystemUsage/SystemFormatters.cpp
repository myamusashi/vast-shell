#include "SystemFormatters.hpp"

namespace vast::sysusage {

    QString formatKiB(quint64 kib) {
        if (kib < 1024) {
            return QString::number(kib) + u" KB";
        }
        if (kib < 1024ULL * 1024ULL) {
            const double megabytes = static_cast<double>(kib) / 1024.0;
            return QString::number(megabytes, 'f', 2) + u" MB";
        }
        const double gigabytes = static_cast<double>(kib) / (1024.0 * 1024.0);
        return QString::number(gigabytes, 'f', 2) + u" GB";
    }

    QString formatUsageMiB(double mib) {
        if (mib < 1.0) {
            const double kilobytes = mib * 1024.0;
            return QString::number(kilobytes, 'f', 2) + u" KB";
        }
        if (mib < 1024.0) {
            return QString::number(mib, 'f', 2) + u" MB";
        }
        const double gigabytes = mib / 1024.0;
        return QString::number(gigabytes, 'f', 2) + u" GB";
    }

    QString formatSpeedMBps(double speedMBps) {
        if (speedMBps < 0.01) {
            return QStringLiteral("0.00 MB/s");
        }
        if (speedMBps < 1.0) {
            const double kilobytesPerSec = speedMBps * 1024.0;
            return QString::number(kilobytesPerSec, 'f', 2) + u" KB/s";
        }
        return QString::number(speedMBps, 'f', 2) + u" MB/s";
    }

    QString formatUptime(quint64 uptimeSeconds) {
        const quint64 days    = uptimeSeconds / 86400;
        const quint64 hours   = (uptimeSeconds % 86400) / 3600;
        const quint64 minutes = (uptimeSeconds % 3600) / 60;

        if (days > 0) {
            return QString::asprintf("%llud %lluh %llum", static_cast<unsigned long long>(days), static_cast<unsigned long long>(hours), static_cast<unsigned long long>(minutes));
        }
        if (hours > 0) {
            return QString::asprintf("%lluh %llum", static_cast<unsigned long long>(hours), static_cast<unsigned long long>(minutes));
        }
        return QString::asprintf("%llum", static_cast<unsigned long long>(minutes));
    }

} // namespace vast::sysusage
