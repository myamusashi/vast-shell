#include "WirelessBitrateReader.hpp"

#include <qdbusextratypes.h>
#include <qdbusmessage.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qvariant.h>

#include <utility>

namespace vast {

    WirelessBitrateReader::WirelessBitrateReader(QObject* parent, QDBusConnection bus, const QString& serviceName) :
        QObject(parent), mBus(std::move(bus)), mServiceName(serviceName) {}

    bool WirelessBitrateReader::requestBitrateMbps(const QString& interfaceName) {
        if (interfaceName.isEmpty() || mRequestInFlight)
            return false;

        if (!mBus.isConnected()) {
            emit bitrateResolved(interfaceName, 0);
            return false;
        }

        mRequestInFlight = true;
        resolveDevicePath(interfaceName);
        return true;
    }

    void WirelessBitrateReader::resolveDevicePath(const QString& interfaceName) {
        const auto cachedPathIterator = mDevicePaths.find(interfaceName);
        if (cachedPathIterator != mDevicePaths.end()) {
            queryBitrate(interfaceName, cachedPathIterator.value());
            return;
        }

        auto message = QDBusMessage::createMethodCall(mServiceName, QStringLiteral("/org/freedesktop/NetworkManager"), QStringLiteral("org.freedesktop.NetworkManager"),
                                                      QStringLiteral("GetDeviceByIpIface"));
        message << interfaceName;

        auto* watcher = new QDBusPendingCallWatcher(mBus.asyncCall(message), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, interfaceName](const QDBusPendingCall* call) {
            watcher->deleteLater();

            QDBusPendingReply<QDBusObjectPath> reply(*call);
            if (!reply.isValid()) {
                finishRequest(interfaceName, 0, false);
                return;
            }

            const QString devicePath = reply.value().path();
            if (devicePath.isEmpty() || devicePath == QStringLiteral("/")) {
                finishRequest(interfaceName, 0, true);
                return;
            }

            mDevicePaths.insert(interfaceName, devicePath);
            queryBitrate(interfaceName, devicePath);
        });
    }

    void WirelessBitrateReader::queryBitrate(const QString& interfaceName, const QString& devicePath) {
        auto message = QDBusMessage::createMethodCall(mServiceName, devicePath, QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("Get"));
        message << QStringLiteral("org.freedesktop.NetworkManager.Device.Wireless") << QStringLiteral("Bitrate");

        auto* watcher = new QDBusPendingCallWatcher(mBus.asyncCall(message), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, interfaceName](const QDBusPendingCall* call) {
            watcher->deleteLater();
            QDBusPendingReply<QDBusVariant> reply(*call);
            if (!reply.isValid()) {
                finishRequest(interfaceName, 0, true);
                return;
            }
            const quint32 bitrateKbps = reply.value().variant().toUInt();
            finishRequest(interfaceName, static_cast<int>(bitrateKbps / 1000), false);
        });
    }

    void WirelessBitrateReader::finishRequest(const QString& interfaceName, int bitrateMbps, bool invalidateCachedPath) {
        if (invalidateCachedPath)
            mDevicePaths.remove(interfaceName);
        mRequestInFlight = false;
        emit bitrateResolved(interfaceName, bitrateMbps);
    }

} // namespace vast
