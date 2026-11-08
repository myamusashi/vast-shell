#include "SystemFormatters.hpp"

namespace vast::sysusage {

    QString formatKiB(quint64 kib) {
        if (kib < 1024) {
            return QString::number(kib) + u" KiB";
        }
        if (kib < 1024ULL * 1024ULL) {
            const double megabytes = static_cast<double>(kib) / 1024.0;
            return QString::number(megabytes, 'f', 2) + u" MiB";
        }
        const double gigabytes = static_cast<double>(kib) / (1024.0 * 1024.0);
        return QString::number(gigabytes, 'f', 2) + u" GiB";
    }

    QString formatUsageMiB(double mib) {
        if (mib < 1.0) {
            const double kilobytes = mib * 1024.0;
            return QString::number(kilobytes, 'f', 2) + u" KiB";
        }
        if (mib < 1024.0) {
            return QString::number(mib, 'f', 2) + u" MiB";
        }
        const double gigabytes = mib / 1024.0;
        return QString::number(gigabytes, 'f', 2) + u" GiB";
    }

    QString formatSpeedMiBps(double speedMiBps) {
        if (speedMiBps <= 0.0) {
            return QStringLiteral("0.00 KiB/s");
        }
        if (speedMiBps < 1.0) {
            const double kilobytesPerSec = speedMiBps * 1024.0;
            return QString::number(kilobytesPerSec, 'f', 2) + u" KiB/s";
        }
        return QString::number(speedMiBps, 'f', 2) + u" MiB/s";
    }

    QString formatUptime(quint64 uptimeSeconds) {
        const quint64 days    = uptimeSeconds / 86400;
        const quint64 hours   = (uptimeSeconds % 86400) / 3600;
        const quint64 minutes = (uptimeSeconds % 3600) / 60;

        if (days > 0) {
            return QStringLiteral(u"%1d %2h %3m").arg(days).arg(hours).arg(minutes);
        }
        if (hours > 0) {
            return QStringLiteral(u"%1h %2m").arg(hours).arg(minutes);
        }
        return QStringLiteral(u"%1m").arg(minutes);
    }

} // namespace vast::sysusage
