#include "WirelessBitrateReader.hpp"

#include <qdbusconnection.h>
#include <qdbusinterface.h>
#include <qdbusmessage.h>
#include <qdbusreply.h>
#include <qvariant.h>

namespace vast {

    WirelessBitrateReader::WirelessBitrateReader() = default;

    QString WirelessBitrateReader::resolveDevicePath(const QString& interfaceName) {
        if (interfaceName.isEmpty())
            return {};

        const auto existingIterator = mDevicePaths.find(interfaceName);
        if (existingIterator != mDevicePaths.end()) {
            return existingIterator.value();
        }

        auto systemBus = QDBusConnection::systemBus();
        if (!systemBus.isConnected())
            return {};

        QDBusMessage message = QDBusMessage::createMethodCall(QStringLiteral("org.freedesktop.NetworkManager"), QStringLiteral("/org/freedesktop/NetworkManager"),
                                                              QStringLiteral("org.freedesktop.NetworkManager"), QStringLiteral("GetDeviceByIpIface"));
        message << interfaceName;

        const QDBusReply<QDBusObjectPath> reply = systemBus.call(message);
        if (!reply.isValid())
            return {};

        QString path = reply.value().path();
        mDevicePaths.insert(interfaceName, path);
        return path;
    }

    int WirelessBitrateReader::queryBitrateMbps(const QString& interfaceName) {
        if (interfaceName.isEmpty())
            return 0;

        const QString devicePath = resolveDevicePath(interfaceName);
        if (devicePath.isEmpty())
            return 0;

        auto systemBus = QDBusConnection::systemBus();
        if (!systemBus.isConnected())
            return 0;

        QDBusInterface wirelessDevice(QStringLiteral("org.freedesktop.NetworkManager"), devicePath, QStringLiteral("org.freedesktop.NetworkManager.Device.Wireless"), systemBus);

        const QVariant bitrateVariant = wirelessDevice.property("Bitrate");
        if (!bitrateVariant.isValid()) {
            // Path might be stale; clear cached path for next retry
            mDevicePaths.remove(interfaceName);
            return 0;
        }

        const quint32 bitrateKbps = bitrateVariant.toUInt();
        return static_cast<int>(bitrateKbps / 1000);
    }

} // namespace vast
