#pragma once

#include <qdbusconnection.h>
#include <qdbusmessage.h>
#include <qlist.h>
#include <qvariant.h>
#include <qdbuscontext.h>
#include <qdbusservicewatcher.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

class QDBusPendingCallWatcher;

namespace vast {

    class BluetoothAgentAdaptor;

    class BluetoothAgentManager : public QObject, public QDBusContext {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON
        Q_PROPERTY(bool active READ active NOTIFY activeChanged)
        Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

      public:
        /// \p bus is injectable so tests can supply a private bus.
        explicit BluetoothAgentManager(QObject* parent = nullptr, QDBusConnection bus = QDBusConnection::systemBus());
        ~BluetoothAgentManager() override;

        BluetoothAgentManager(const BluetoothAgentManager&)            = delete;
        BluetoothAgentManager& operator=(const BluetoothAgentManager&) = delete;
        BluetoothAgentManager(BluetoothAgentManager&&)                 = delete;
        BluetoothAgentManager& operator=(BluetoothAgentManager&&)      = delete;

        [[nodiscard]] bool     active() const noexcept {
            return mActive;
        }
        [[nodiscard]] bool busy() const noexcept {
            return !mPending.isEmpty();
        }

        Q_INVOKABLE void                         providePinCode(const QString& devicePath, const QString& pin);
        Q_INVOKABLE void                         providePasskey(const QString& devicePath, quint32 passkey);
        Q_INVOKABLE void                         confirmPairing(const QString& devicePath, bool accept);
        Q_INVOKABLE void                         authorizeService(const QString& devicePath, bool accept);

        Q_INVOKABLE [[nodiscard]] static QString deviceNameForPath(const QString& devicePath);

        // Called by adaptor
        void handleRequestPinCode(const QString& devicePath, const QDBusMessage& msg);
        void handleRequestPasskey(const QString& devicePath, const QDBusMessage& msg);
        void handleDisplayPasskey(const QString& devicePath, quint32 passkey, quint16 entered);
        void handleRequestConfirmation(const QString& devicePath, quint32 passkey, const QDBusMessage& msg);
        void handleAuthorizeService(const QString& devicePath, const QString& uuid, const QDBusMessage& msg);
        void handleCancel();
        void handleRelease();

      Q_SIGNALS:
        void activeChanged();
        void busyChanged();
        void pinCodeRequested(const QString& devicePath, const QString& deviceName);
        void passkeyRequested(const QString& devicePath, const QString& deviceName);
        void passkeyDisplayed(const QString& devicePath, quint32 passkey, quint16 entered);
        void confirmationRequested(const QString& devicePath, const QString& deviceName, quint32 passkey);
        void authorizationRequested(const QString& devicePath, const QString& deviceName, const QString& uuid);
        void pairingCancelled(const QString& devicePath);

      private:
        [[nodiscard]] QDBusMessage   agentManagerCall(const QString& method, const QList<QVariant>& args) const;
        void                         ensureRegistered();
        void                         onRegisterAgentFinished(QDBusPendingCallWatcher* watcher);
        void                         onRequestDefaultAgentFinished(QDBusPendingCallWatcher* watcher);
        void                         reRegisterIfNeeded(const QString& newOwner);

        [[nodiscard]] static QString resolveDeviceName(const QString& devicePath);

        // Shared tail for the four completion entry points. On a hit, removes
        // the pending message and returns it via reply; on a miss, warns and
        // returns false.
        bool                         takePending(const QString& devicePath, const char* callerName, QDBusMessage& reply);

        void                         storePending(const QString& devicePath, const QDBusMessage& msg);

        static constexpr const char* K_AGENT_PATH    = "/io/quickshell/BluetoothAgent";
        static constexpr const char* K_CAPABILITY    = "KeyboardDisplay";
        static constexpr const char* K_BLUES_SERVICE = "org.bluez";
        static constexpr const char* K_BLUES_PATH    = "/org/bluez";
        static constexpr const char* K_BLUES_IFACE   = "org.bluez.AgentManager1";

        QDBusConnection              mSystemBus;
        QDBusServiceWatcher*         mWatcher{nullptr};
        BluetoothAgentAdaptor*       mAdaptor{nullptr};

        bool                         mActive{false};
        bool                         mActivationInFlight{false};

        QHash<QString, QDBusMessage> mPending;
    };

} // namespace vast
