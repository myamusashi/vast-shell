#include "KdeConnectShare.hpp"
#include <qdbuspendingcall.h>
#include <qdebug.h>
#include <qlogging.h>
#include <qobject.h>
#include <qstringlist.h>
#include <qurl.h>
#include <qvariant.h>

namespace vast {

    namespace {
        constexpr auto SERVICE         = "org.kde.kdeconnect";
        constexpr auto PATH            = "/modules/kdeconnect/devices/%1/share";
        constexpr auto IFACE           = "org.kde.kdeconnect.device.share";
        constexpr auto MEMBER          = "shareUrls";
        constexpr int  CALL_TIMEOUT_MS = 15000;
    } // namespace

    KdeConnectShare::KdeConnectShare(QObject* parent, QDBusConnection bus) : QObject(parent), mBus(std::move(bus)) {}

    KdeConnectShare::~KdeConnectShare() = default;

    QDBusMessage KdeConnectShare::buildShareMessage(const QString& deviceId, const QString& localPath) {
        if (deviceId.isEmpty() || localPath.isEmpty())
            return {};

        QDBusMessage message = QDBusMessage::createMethodCall(QLatin1String(SERVICE), QLatin1String(PATH).arg(deviceId), QLatin1String(IFACE), QLatin1String(MEMBER));
        message.setArguments({QStringList{QUrl::fromLocalFile(localPath).toString(QUrl::FullyEncoded)}});
        return message;
    }

    void KdeConnectShare::share(const QString& deviceId, const QString& localPath) {
        const QDBusMessage message = buildShareMessage(deviceId, localPath);
        if (message.type() == QDBusMessage::InvalidMessage) {
            const QString reason = deviceId.isEmpty() ? QStringLiteral("empty device id") : QStringLiteral("empty path");
            qWarning() << "[Vast.Utils] KDE Connect share rejected:" << reason;
            Q_EMIT shareFailed(deviceId, reason);
            return;
        }

        auto* watcher = new QDBusPendingCallWatcher(mBus.asyncCall(message, CALL_TIMEOUT_MS), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, deviceId]() {
            const QDBusMessage reply = watcher->reply();
            watcher->deleteLater();

            if (reply.type() == QDBusMessage::ErrorMessage) {
                qWarning() << "[Vast.Utils] KDE Connect share failed:" << reply.errorMessage();
                Q_EMIT shareFailed(deviceId, reply.errorMessage());
                return;
            }

            Q_EMIT shared(deviceId);
        });
    }

} // namespace vast
