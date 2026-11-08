#pragma once

#include <qstring.h>
#include <qtypes.h>

namespace vast::sysusage {

    [[nodiscard]] QString formatKiB(quint64 kib);
    [[nodiscard]] QString formatUsageMiB(double mib);
    [[nodiscard]] QString formatSpeedMiBps(double speedMiBps);
    [[nodiscard]] QString formatUptime(quint64 uptimeSeconds);

} // namespace vast::sysusage
