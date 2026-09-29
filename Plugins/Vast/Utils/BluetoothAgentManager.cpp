#include "BluetoothAgentManager.hpp"
#include "BluetoothAgentAdaptor.hpp"

#include <QDBusPendingCallWatcher>
#include <qdbuspendingreply.h>
#include <qloggingcategory.h>

#include <utility>

namespace vast {

    BluetoothAgentManager::BluetoothAgentManager(QObject* parent, QDBusConnection bus) : QObject(parent), mSystemBus(std::move(bus)), mAdaptor(new BluetoothAgentAdaptor(this)) {

        mWatcher = new QDBusServiceWatcher(QStringLiteral("org.bluez"), mSystemBus, QDBusServiceWatcher::WatchForOwnerChange, this);
        connect(mWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this, [this](const QString& service, const QString& oldOwner, const QString& newOwner) {
            Q_UNUSED(service);
            Q_UNUSED(oldOwner);
            reRegisterIfNeeded(newOwner);
        });

        ensureRegistered();
    }

    BluetoothAgentManager::~BluetoothAgentManager() {
        if (mActive && mSystemBus.isConnected()) {
            mSystemBus.asyncCall(agentManagerCall(QStringLiteral("UnregisterAgent"), {QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH)))}));
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
        }
        for (auto it = mPending.constBegin(); it != mPending.constEnd(); ++it)
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Agent released")));

        mPending.clear();
    }

    QDBusMessage BluetoothAgentManager::agentManagerCall(const QString& method, const QList<QVariant>& args) {
        auto msg = QDBusMessage::createMethodCall(QString::fromLatin1(K_BLUES_SERVICE), QString::fromLatin1(K_BLUES_PATH), QString::fromLatin1(K_BLUES_IFACE), method);
        for (const QVariant& a : args)
            msg << a;
        // Off: the owner watcher covers a late bluetoothd, and the shell must
        // not start a Bluetooth stack the user disabled.
        msg.setAutoStartService(false);
        return msg;
    }

    void BluetoothAgentManager::ensureRegistered() {
        if (mActivationInFlight || mActive)
            return;
        if (!mSystemBus.isConnected()) {
            qWarning() << "[Vast.BluetoothAgentManager] System bus not connected";
            return;
        }

        mActivationInFlight = true;

        // Export this object (manager) which owns the Adaptor as org.bluez.Agent1.
        const bool registered = mSystemBus.registerObject(QString::fromLatin1(K_AGENT_PATH), this);
        if (!registered) {
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            if (!mSystemBus.registerObject(QString::fromLatin1(K_AGENT_PATH), this)) {
                qWarning() << "[Vast.BluetoothAgentManager] registerObject failed:" << mSystemBus.lastError().message();
                mActivationInFlight = false;
                return;
            }
        }

        // No pre-flight check: QDBusInterface::isValid() blocks in the
        // constructor and reads stale inside the owner-changed handler.
        auto* watcher = new QDBusPendingCallWatcher(
            mSystemBus.asyncCall(
                agentManagerCall(QStringLiteral("RegisterAgent"), {QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH))), QString::fromLatin1(K_CAPABILITY)})),
            this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, &BluetoothAgentManager::onRegisterAgentFinished);
    }

    void BluetoothAgentManager::onRegisterAgentFinished(QDBusPendingCallWatcher* watcher) {
        watcher->deleteLater();
        const auto& reply = *watcher;
        // After a NoReply the call may have landed, so AlreadyExists is success.
        if (reply.isError() && reply.error().name() != QLatin1String("org.bluez.Error.AlreadyExists")) {
            qWarning() << "[Vast.BluetoothAgentManager] RegisterAgent failed:" << reply.error().message();
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            mActivationInFlight = false;
            return;
        }

        auto* next = new QDBusPendingCallWatcher(
            mSystemBus.asyncCall(agentManagerCall(QStringLiteral("RequestDefaultAgent"), {QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH)))})), this);
        connect(next, &QDBusPendingCallWatcher::finished, this, &BluetoothAgentManager::onRequestDefaultAgentFinished);
    }

    void BluetoothAgentManager::onRequestDefaultAgentFinished(QDBusPendingCallWatcher* watcher) {
        watcher->deleteLater();
        const auto& reply = *watcher;
        if (reply.isError()) {
            // A non-default agent is never asked to handle a pairing.
            qWarning() << "[Vast.BluetoothAgentManager] RequestDefaultAgent failed:" << reply.error().message();
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            mActivationInFlight = false;
            Q_EMIT activeChanged();
            return;
        }

        mActive             = true;
        mActivationInFlight = false;
        Q_EMIT activeChanged();
        qInfo() << "[Vast.BluetoothAgentManager] Registered KeyboardDisplay at" << K_AGENT_PATH;
    }

    void BluetoothAgentManager::reRegisterIfNeeded(const QString& newOwner) {
        if (newOwner.isEmpty()) {
            // bluetoothd went away. The reply is defensive: bluetoothd is both
            // the name owner and the only caller, so nobody is waiting.
            // Detached before iterating, as in handleCancel.
            auto pending = std::exchange(mPending, {});
            for (auto it = pending.cbegin(); it != pending.cend(); ++it) {
                mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("bluetoothd went away")));
                Q_EMIT pairingCancelled(it.key());
            }

            if (!pending.isEmpty())
                Q_EMIT busyChanged();
            mActive = false;
            Q_EMIT activeChanged();
            return;
        }
        // bluetoothd (re)appeared; re-register if not active
        if (!mActive && !mActivationInFlight)
            ensureRegistered();
    }

    [[nodiscard]] QString BluetoothAgentManager::resolveDeviceName(const QString& devicePath) {
        // Best-effort only: derives a MAC-shaped label from the object path.
        // Not the device's real name -- QML should prefer the device list.
        if (devicePath.isEmpty())
            return {};
        QString tail = devicePath.section(QLatin1Char('/'), -1);
        if (tail.startsWith(QStringLiteral("dev_")))
            return tail.mid(4).replace(QLatin1Char('_'), QLatin1Char(':'));
        return tail;
    }

    QString BluetoothAgentManager::deviceNameForPath(const QString& devicePath) {
        return resolveDeviceName(devicePath);
    }

    void BluetoothAgentManager::storePending(const QString& devicePath, const QDBusMessage& msg) {
        // mPending is keyed by device path, so a second request for the same
        // device would orphan the first caller.
        const auto it = mPending.constFind(devicePath);
        if (it != mPending.constEnd())
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Superseded by a newer request")));
        mPending.insert(devicePath, msg);
    }

    void BluetoothAgentManager::handleRequestPinCode(const QString& devicePath, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestPinCode" << devicePath;
        storePending(devicePath, msg);
        Q_EMIT busyChanged();
        Q_EMIT pinCodeRequested(devicePath, resolveDeviceName(devicePath));
    }

    void BluetoothAgentManager::handleRequestPasskey(const QString& devicePath, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestPasskey" << devicePath;
        storePending(devicePath, msg);
        Q_EMIT busyChanged();
        Q_EMIT passkeyRequested(devicePath, resolveDeviceName(devicePath));
    }

    void BluetoothAgentManager::handleDisplayPasskey(const QString& devicePath, quint32 passkey, quint16 entered) {
        qInfo() << "[Vast.BluetoothAgentManager] DisplayPasskey" << devicePath << passkey << entered;
        // Informational only, BlueZ does not wait on a reply for DisplayPasskey.
        Q_EMIT passkeyDisplayed(devicePath, passkey, entered);
    }

    void BluetoothAgentManager::handleRequestConfirmation(const QString& devicePath, quint32 passkey, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestConfirmation" << devicePath << passkey;
        storePending(devicePath, msg);
        Q_EMIT busyChanged();
        Q_EMIT confirmationRequested(devicePath, resolveDeviceName(devicePath), passkey);
    }

    void BluetoothAgentManager::handleAuthorizeService(const QString& devicePath, const QString& uuid, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] AuthorizeService" << devicePath << uuid;
        storePending(devicePath, msg);
        Q_EMIT busyChanged();
        Q_EMIT authorizationRequested(devicePath, resolveDeviceName(devicePath), uuid);
    }

    void BluetoothAgentManager::handleCancel() {
        qInfo() << "[Vast.BluetoothAgentManager] Cancel()";
        // Detached before iterating: a pairingCancelled handler may reply and
        // erase from mPending, invalidating a live iterator.
        auto pending = std::exchange(mPending, {});
        for (auto it = pending.cbegin(); it != pending.cend(); ++it) {
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Canceled")));
            Q_EMIT pairingCancelled(it.key());
        }
        if (!pending.isEmpty())
            Q_EMIT busyChanged();
    }

    void BluetoothAgentManager::handleRelease() {
        qInfo() << "[Vast.BluetoothAgentManager] Release() — agent released by bluetoothd";
        // Detached before iterating, as in handleCancel.
        auto pending = std::exchange(mPending, {});
        for (auto it = pending.cbegin(); it != pending.cend(); ++it) {
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Released")));
            Q_EMIT pairingCancelled(it.key());
        }
        if (!pending.isEmpty())
            Q_EMIT busyChanged();
        mActive             = false;
        mActivationInFlight = false;
        Q_EMIT activeChanged();
    }

    bool BluetoothAgentManager::takePending(const QString& devicePath, const char* callerName, QDBusMessage& reply) {
        auto it = mPending.constFind(devicePath);
        if (it == mPending.constEnd()) {
            qWarning() << "[Vast.BluetoothAgentManager]" << callerName << "no pending for" << devicePath;
            return false;
        }
        reply = it.value();
        mPending.remove(devicePath);
        Q_EMIT busyChanged();
        return true;
    }

    void BluetoothAgentManager::providePinCode(const QString& devicePath, const QString& pin) {
        QDBusMessage msg;
        if (!takePending(devicePath, "providePinCode", msg))
            return;
        if (pin.isEmpty())
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
        else
            mSystemBus.send(msg.createReply(QVariant::fromValue(pin)));
    }

    void BluetoothAgentManager::providePasskey(const QString& devicePath, quint32 passkey) {
        QDBusMessage msg;
        if (!takePending(devicePath, "providePasskey", msg))
            return;
        mSystemBus.send(msg.createReply(QVariant::fromValue(passkey)));
    }

    void BluetoothAgentManager::confirmPairing(const QString& devicePath, bool accept) {
        QDBusMessage msg;
        if (!takePending(devicePath, "confirmPairing", msg))
            return;
        if (accept)
            mSystemBus.send(msg.createReply());
        else
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
    }

    void BluetoothAgentManager::authorizeService(const QString& devicePath, bool accept) {
        QDBusMessage msg;
        if (!takePending(devicePath, "authorizeService", msg))
            return;
        if (accept)
            mSystemBus.send(msg.createReply());
        else
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
    }

} // namespace vast
