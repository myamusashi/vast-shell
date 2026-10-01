#pragma once

#include <qdbusconnection.h>
#include <qdbusmessage.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

namespace vast {

    class KdeConnectShare : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

      public:
        explicit KdeConnectShare(QObject* parent = nullptr, QDBusConnection bus = QDBusConnection::sessionBus());
        ~KdeConnectShare() override;

        KdeConnectShare(const KdeConnectShare&)                        = delete;
        KdeConnectShare& operator=(const KdeConnectShare&)             = delete;
        KdeConnectShare(KdeConnectShare&&)                             = delete;
        KdeConnectShare&                  operator=(KdeConnectShare&&) = delete;

        Q_INVOKABLE void                  share(const QString& deviceId, const QString& localPath);
        [[nodiscard]] static QDBusMessage buildShareMessage(const QString& deviceId, const QString& localPath);

      Q_SIGNALS:
        void shared(const QString& deviceId);
        void shareFailed(const QString& deviceId, const QString& errorMessage);

      private:
        QDBusConnection mBus;
    };

} // namespace vast
