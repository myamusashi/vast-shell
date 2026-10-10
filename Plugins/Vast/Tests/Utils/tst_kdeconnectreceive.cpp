#include <qcoreapplication.h>
#include <qdbusconnection.h>
#include <qdbusmessage.h>
#include <qfile.h>
#include <qprocess.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtemporarydir.h>
#include <qtest.h>
#include <qvariant.h>

#include <memory>
#include <optional>

#include "../../Utils/KdeConnectReceive.hpp"

namespace {

    constexpr QLatin1StringView kService     = QLatin1StringView("org.kde.kdeconnect");
    constexpr QLatin1StringView kDeviceId    = QLatin1StringView("abcdef0123456789abcdef0123456789");
    constexpr QLatin1StringView kOtherId     = QLatin1StringView("0123456789abcdef0123456789abcdef");
    constexpr QLatin1StringView kShareIface  = QLatin1StringView("org.kde.kdeconnect.device.share");
    constexpr QLatin1StringView kMember      = QLatin1StringView("shareReceived");
    constexpr QLatin1StringView kDestination = QLatin1StringView("file:///home/user/a%20b.txt");

    constexpr int               kTimeoutMs = 5000;
    constexpr int               kQuietMs   = 500;

    const char* const           kBusConfigTemplate = "<busconfig>\n"
                                                     "  <type>session</type>\n"
                                                     "  <listen>%1</listen>\n"
                                                     "  <keep_umask/>\n"
                                                     "  <policy context=\"default\">\n"
                                                     "    <allow user=\"*\"/>\n"
                                                     "    <allow own=\"*\"/>\n"
                                                     "    <allow send_type=\"method_call\"/>\n"
                                                     "    <allow send_type=\"method_return\"/>\n"
                                                     "    <allow send_type=\"error\"/>\n"
                                                     "    <allow send_type=\"signal\"/>\n"
                                                     "    <allow receive_type=\"method_call\"/>\n"
                                                     "    <allow receive_type=\"method_return\"/>\n"
                                                     "    <allow receive_type=\"error\"/>\n"
                                                     "    <allow receive_type=\"signal\"/>\n"
                                                     "  </policy>\n"
                                                     "</busconfig>\n";

    [[nodiscard]] QString       describeBusFailure(QProcess& daemon, const QString& address, const QString& step) {
        if (daemon.state() == QProcess::NotRunning && daemon.error() != QProcess::UnknownError)
            return QStringLiteral("could not run dbus-daemon: %1").arg(daemon.errorString());
        if (address.isEmpty())
            return QStringLiteral("dbus-daemon printed no address, exit %1, stderr: %2").arg(daemon.exitStatus()).arg(QString::fromUtf8(daemon.readAllStandardError()).trimmed());
        return QStringLiteral("private bus setup failed at %1 on %2").arg(step, address);
    }

} // namespace

class TestKdeConnectReceive : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void cleanupTestCase();

    void sharePathBuildsTheDeviceSharePath();

    void shareReceivedEmitsFileReceivedWithDeviceAndDestination();
    void unwatchedDevicePathsAreIgnored();
    void repeatedWatchCallsDoNotDoubleReport();
    void emptyDeviceIdsAreIgnored();
    void wrongSignalSignatureIsIgnored();

  private:
    // The daemon lives in another process, so its signals arrive over the bus.
    void                                     sendShareReceived(const QString& deviceId, const QString& signature = QStringLiteral("s"));

    QProcess                                 daemon;
    std::unique_ptr<QTemporaryDir>           busDir;
    std::optional<QDBusConnection>           serviceBus;
    std::optional<QDBusConnection>           watchBus;
    QString                                  address;
    std::unique_ptr<vast::KdeConnectReceive> receive;
    QString                                  busFailure;
    bool                                     haveBus{false};
};

void TestKdeConnectReceive::initTestCase() {
    qputenv("DBUS_SESSION_BUS_ADDRESS", "unix:path=/nonexistent-session-bus");

    busDir = std::make_unique<QTemporaryDir>();
    if (!busDir->isValid()) {
        busFailure = QStringLiteral("no temporary dir");
        return;
    }

    const QString socketPath = busDir->filePath(QStringLiteral("bus"));
    const QString configPath = busDir->filePath(QStringLiteral("session.conf"));
    {
        QFile config(configPath);
        if (!config.open(QIODeviceBase::WriteOnly | QIODeviceBase::Text)) {
            busFailure = QStringLiteral("wrote no config at %1").arg(configPath);
            return;
        }
        config.write(QString::fromLatin1(kBusConfigTemplate).arg(QStringLiteral("unix:path=%1").arg(socketPath)).toLatin1());
        config.close();
    }

    daemon.start(QStringLiteral("dbus-daemon"), {QStringLiteral("--config-file=%1").arg(configPath), QStringLiteral("--print-address"), QStringLiteral("--nofork")});
    if (!daemon.waitForStarted(kTimeoutMs)) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("waitForStarted"));
        return;
    }

    if (daemon.waitForReadyRead(kTimeoutMs))
        address = QString::fromUtf8(daemon.readLine()).trimmed();
    if (address.isEmpty()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("print-address"));
        return;
    }

    // Sender and watcher sit on separate connections, so the signal travels over
    // the bus exactly as the daemon's does.
    serviceBus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-kdeconnectreceive-service")));
    if (!serviceBus->isConnected()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("connectToBus(service)"));
        return;
    }
    if (!serviceBus->registerService(QString(kService))) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("registerService %1").arg(QString(kService)));
        return;
    }

    watchBus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-kdeconnectreceive-watch")));
    if (!watchBus->isConnected()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("connectToBus(watch)"));
        return;
    }

    receive = std::make_unique<vast::KdeConnectReceive>(nullptr, *watchBus);
    haveBus = true;
}

void TestKdeConnectReceive::cleanupTestCase() {
    receive.reset();
    if (serviceBus)
        serviceBus->unregisterService(QString(kService));
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-kdeconnectreceive-watch"));
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-kdeconnectreceive-service"));
    if (daemon.state() != QProcess::NotRunning) {
        daemon.kill();
        daemon.waitForFinished(kTimeoutMs);
    }
}

void TestKdeConnectReceive::sendShareReceived(const QString& deviceId, const QString& signature) {
    QDBusMessage message = QDBusMessage::createSignal(vast::KdeConnectReceive::sharePath(deviceId), QString(kShareIface), QString(kMember));
    if (signature == QLatin1String("s"))
        message.setArguments({QString(kDestination)});
    else
        message.setArguments({QString(kDestination), QStringLiteral("extra")});
    QVERIFY(serviceBus->send(message));
}

void TestKdeConnectReceive::sharePathBuildsTheDeviceSharePath() {
    QCOMPARE(vast::KdeConnectReceive::sharePath(QString(kDeviceId)), QStringLiteral("/modules/kdeconnect/devices/%1/share").arg(QString(kDeviceId)));
    QVERIFY(vast::KdeConnectReceive::sharePath(QStringLiteral("a/b")).contains(QLatin1String("a/b")));
}

void TestKdeConnectReceive::shareReceivedEmitsFileReceivedWithDeviceAndDestination() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    receive->watchDevices({QString(kDeviceId)});

    QSignalSpy receivedSpy(receive.get(), &vast::KdeConnectReceive::fileReceived);
    sendShareReceived(QString(kDeviceId));

    QVERIFY(receivedSpy.wait(kTimeoutMs));
    QCOMPARE(receivedSpy.size(), 1);
    QCOMPARE(receivedSpy.constFirst().constFirst().toString(), QString(kDeviceId));
    QCOMPARE(receivedSpy.constFirst().constLast().toString(), QString(kDestination));
}

void TestKdeConnectReceive::unwatchedDevicePathsAreIgnored() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    receive->watchDevices({QString(kDeviceId)});

    QSignalSpy receivedSpy(receive.get(), &vast::KdeConnectReceive::fileReceived);
    sendShareReceived(QString(kOtherId));

    QVERIFY(!receivedSpy.wait(kQuietMs));
    QCOMPARE(receivedSpy.size(), 0);
}

void TestKdeConnectReceive::repeatedWatchCallsDoNotDoubleReport() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    receive->watchDevices({QString(kDeviceId)});
    receive->watchDevices({QString(kDeviceId)});

    QSignalSpy receivedSpy(receive.get(), &vast::KdeConnectReceive::fileReceived);
    sendShareReceived(QString(kDeviceId));

    QVERIFY(receivedSpy.wait(kTimeoutMs));
    QTest::qWait(kQuietMs);
    QCOMPARE(receivedSpy.size(), 1);
}

void TestKdeConnectReceive::emptyDeviceIdsAreIgnored() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    // Blank ids are skipped outright, so no hook exists for the path used here.
    receive->watchDevices({QString(), QStringLiteral("   ")});

    QSignalSpy receivedSpy(receive.get(), &vast::KdeConnectReceive::fileReceived);
    sendShareReceived(QString(kOtherId));

    QVERIFY(!receivedSpy.wait(kQuietMs));
    QCOMPARE(receivedSpy.size(), 0);
}

void TestKdeConnectReceive::wrongSignalSignatureIsIgnored() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    receive->watchDevices({QString(kDeviceId)});

    QSignalSpy receivedSpy(receive.get(), &vast::KdeConnectReceive::fileReceived);
    sendShareReceived(QString(kDeviceId), QStringLiteral("ss"));

    QVERIFY(!receivedSpy.wait(kQuietMs));
    QCOMPARE(receivedSpy.size(), 0);
}

QTEST_GUILESS_MAIN(TestKdeConnectReceive)
#include "tst_kdeconnectreceive.moc"
