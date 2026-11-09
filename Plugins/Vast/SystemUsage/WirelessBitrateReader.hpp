#pragma once

#include <qdbusconnection.h>
#include <qhash.h>
#include <qobject.h>
#include <qstring.h>
#include <qtmetamacros.h>

namespace vast {

    class WirelessBitrateReader final : public QObject {
        Q_OBJECT

      public:
        explicit WirelessBitrateReader(QObject* parent = nullptr, QDBusConnection bus = QDBusConnection::systemBus(),
                                       QString serviceName = QStringLiteral("org.freedesktop.NetworkManager"));

        bool requestBitrateMbps(const QString& interfaceName);

      Q_SIGNALS:
        void bitrateResolved(const QString& interfaceName, int bitrateMbps);

      private:
        void                    resolveDevicePath(const QString& interfaceName);
        void                    queryBitrate(const QString& interfaceName, const QString& devicePath);
        void                    finishRequest(const QString& interfaceName, int bitrateMbps, bool invalidateCachedPath);

        QDBusConnection         mBus;
        QString                 mServiceName;
        QHash<QString, QString> mDevicePaths;
        bool                    mRequestInFlight{false};
    };

} // namespace vast
