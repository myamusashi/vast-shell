#pragma once

#include <qcontainerfwd.h>
#include <qhash.h>
#include <qstring.h>

namespace vast {

    class WirelessBitrateReader {
      public:
        WirelessBitrateReader();

        [[nodiscard]] int queryBitrateMbps(const QString& interfaceName);

      private:
        QHash<QString, QString> mDevicePaths;

        [[nodiscard]] QString   resolveDevicePath(const QString& interfaceName);
    };

} // namespace vast
