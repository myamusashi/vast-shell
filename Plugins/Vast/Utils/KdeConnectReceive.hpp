#pragma once

#include <qdbusconnection.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>

namespace vast {

    class KdeConnectShareEndpoint : public QObject {
        Q_OBJECT

      public:
        explicit KdeConnectShareEndpoint(QString deviceId, QObject* parent = nullptr);
        ~KdeConnectShareEndpoint() override;

        KdeConnectShareEndpoint(const KdeConnectShareEndpoint&)            = delete;
        KdeConnectShareEndpoint& operator=(const KdeConnectShareEndpoint&) = delete;
        KdeConnectShareEndpoint(KdeConnectShareEndpoint&&)                 = delete;
        KdeConnectShareEndpoint& operator=(KdeConnectShareEndpoint&&)      = delete;

      public Q_SLOTS:
        void shareReceived(const QString& destinationUrl);

      Q_SIGNALS:
        void fileReceived(const QString& deviceId, const QString& destinationUrl);

      private:
        QString mDeviceId;
    };

    class KdeConnectReceive : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

      public:
        explicit KdeConnectReceive(QObject* parent = nullptr, QDBusConnection bus = QDBusConnection::sessionBus());
        ~KdeConnectReceive() override;

        KdeConnectReceive(const KdeConnectReceive&)                 = delete;
        KdeConnectReceive& operator=(const KdeConnectReceive&)      = delete;
        KdeConnectReceive(KdeConnectReceive&&)                      = delete;
        KdeConnectReceive&           operator=(KdeConnectReceive&&) = delete;

        Q_INVOKABLE void             watchDevices(const QStringList& deviceIds);

        [[nodiscard]] static QString sharePath(const QString& deviceId);

      Q_SIGNALS:
        void fileReceived(const QString& deviceId, const QString& destinationUrl);

      private:
        QDBusConnection                          mBus;
        QHash<QString, KdeConnectShareEndpoint*> mEndpoints;
    };

} // namespace vast
