#include "KdeConnectReceive.hpp"
#include <qdebug.h>
#include <qlogging.h>
#include <qobjectdefs.h>

namespace vast {

    namespace {
        constexpr auto IFACE      = "org.kde.kdeconnect.device.share";
        constexpr auto MEMBER     = "shareReceived";
        constexpr auto SIGNATURE  = "s";
        constexpr auto SHARE_PATH = "/modules/kdeconnect/devices/%1/share";
    } // namespace

    KdeConnectShareEndpoint::KdeConnectShareEndpoint(QString deviceId, QObject* parent) : QObject(parent), mDeviceId(std::move(deviceId)) {}

    KdeConnectShareEndpoint::~KdeConnectShareEndpoint() = default;

    void KdeConnectShareEndpoint::shareReceived(const QString& destinationUrl) {
        Q_EMIT fileReceived(mDeviceId, destinationUrl);
    }

    KdeConnectReceive::KdeConnectReceive(QObject* parent, QDBusConnection bus) : QObject(parent), mBus(std::move(bus)) {}

    KdeConnectReceive::~KdeConnectReceive() {
        const auto* const slot = SLOT(shareReceived(QString));
        for (auto it = mEndpoints.cbegin(); it != mEndpoints.cend(); ++it)
            mBus.disconnect(QString(), sharePath(it.key()), QLatin1String(IFACE), QLatin1String(MEMBER), QLatin1String(SIGNATURE), it.value(), slot);
    }

    QString KdeConnectReceive::sharePath(const QString& deviceId) {
        return QString::fromLatin1(SHARE_PATH).arg(deviceId);
    }

    void KdeConnectReceive::watchDevices(const QStringList& deviceIds) {
        const auto* const slot = SLOT(shareReceived(QString));
        for (const QString& deviceId : deviceIds) {
            if (deviceId.trimmed().isEmpty() || mEndpoints.contains(deviceId))
                continue;

            auto* endpoint = new KdeConnectShareEndpoint(deviceId, this);
            connect(endpoint, &KdeConnectShareEndpoint::fileReceived, this, &KdeConnectReceive::fileReceived);
            if (!mBus.connect(QString(), sharePath(deviceId), QLatin1String(IFACE), QLatin1String(MEMBER), QLatin1String(SIGNATURE), endpoint, slot))
                qWarning() << "[Vast.Utils] KDE Connect receive watcher could not hook device" << deviceId;

            mEndpoints.insert(deviceId, endpoint);
        }
    }

} // namespace vast
