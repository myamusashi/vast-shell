#include <qcoreapplication.h>
#include <qdbusconnection.h>
#include <qdbuscontext.h>
#include <qdbusmessage.h>
#include <qfile.h>
#include <qprocess.h>
#include <qtemporarydir.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include <memory>
#include <optional>

#include "../../Utils/KdeConnectShare.hpp"

namespace {

    constexpr QLatin1StringView kService     = QLatin1StringView("org.kde.kdeconnect");
    constexpr QLatin1StringView kDeviceId    = QLatin1StringView("abcdef0123456789abcdef0123456789");
    constexpr QLatin1StringView kSharePath   = QLatin1StringView("/modules/kdeconnect/devices/abcdef0123456789abcdef0123456789/share");
    constexpr QLatin1StringView kShareIface  = QLatin1StringView("org.kde.kdeconnect.device.share");
    constexpr QLatin1StringView kShareMember = QLatin1StringView("shareUrls");

    constexpr int               kTimeoutMs = 5000;

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

class FakeSharePlugin : public QObject, public QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.kdeconnect.device.share")

  public:
    QStringList lastUrls;
    int         calls = 0;
    bool        failNext{false};

    void        reset() {
        lastUrls.clear();
        calls    = 0;
        failNext = false;
    }

  public Q_SLOTS:
    void shareUrls(const QStringList& urls) {
        ++calls;
        lastUrls = urls;
        if (failNext)
            sendErrorReply(QStringLiteral("org.kde.kdeconnect.Error.NoSuchDevice"), QStringLiteral("No such object path '%1'").arg(QString(kSharePath)));
    }
};

class TestKdeConnectShare : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void cleanupTestCase();

    void buildShareMessageUsesTheShareObjectPathAndMember();
    void buildShareMessageIsNullForAnEmptyDeviceIdOrPath();

    void successfulShareUrlsEmitsShared();
    void errorReplyEmitsShareFailedWithTheDaemonMessage();
    void emptyInputsFailWithoutTouchingTheBus();

  private:
    QProcess                               daemon;
    std::unique_ptr<QTemporaryDir>         busDir;
    std::optional<QDBusConnection>         bus;
    QString                                address;
    FakeSharePlugin                        plugin;
    std::unique_ptr<vast::KdeConnectShare> share;
    QString                                busFailure;
    bool                                   haveBus{false};
};

void TestKdeConnectShare::initTestCase() {
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

    bus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-kdeconnectshare")));
    if (!bus->isConnected()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("connectToBus"));
        return;
    }

    if (!bus->registerObject(QString(kSharePath), &plugin, QDBusConnection::ExportAllSlots)) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("registerObject"));
        return;
    }
    if (!bus->registerService(QString(kService))) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("registerService %1").arg(QString(kService)));
        return;
    }

    share   = std::make_unique<vast::KdeConnectShare>(nullptr, *bus);
    haveBus = true;
}

void TestKdeConnectShare::cleanupTestCase() {
    share.reset();
    if (bus) {
        bus->unregisterService(QString(kService));
        bus->unregisterObject(QString(kSharePath));
    }
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-kdeconnectshare"));
    if (daemon.state() != QProcess::NotRunning) {
        daemon.kill();
        daemon.waitForFinished(kTimeoutMs);
    }
}

void TestKdeConnectShare::buildShareMessageUsesTheShareObjectPathAndMember() {
    const QDBusMessage message = vast::KdeConnectShare::buildShareMessage(QString(kDeviceId), QStringLiteral("/tmp/a b.txt"));

    QCOMPARE(message.service(), QString(kService));
    QCOMPARE(message.path(), QString(kSharePath));
    QCOMPARE(message.interface(), QString(kShareIface));
    QCOMPARE(message.member(), QString(kShareMember));
    QCOMPARE(message.type(), QDBusMessage::MethodCallMessage);

    QCOMPARE(message.arguments().size(), 1);
    const QStringList urls = message.arguments().constFirst().toStringList();
    QCOMPARE(urls.size(), 1);
    QCOMPARE(urls.constFirst(), QStringLiteral("file:///tmp/a%20b.txt"));
}

void TestKdeConnectShare::buildShareMessageIsNullForAnEmptyDeviceIdOrPath() {
    QVERIFY(vast::KdeConnectShare::buildShareMessage(QString(), QStringLiteral("/tmp/a.txt")).type() == QDBusMessage::InvalidMessage);
    QVERIFY(vast::KdeConnectShare::buildShareMessage(QString(kDeviceId), QString()).type() == QDBusMessage::InvalidMessage);
}

void TestKdeConnectShare::successfulShareUrlsEmitsShared() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    plugin.reset();
    QSignalSpy sharedSpy(share.get(), &vast::KdeConnectShare::shared);
    QSignalSpy failedSpy(share.get(), &vast::KdeConnectShare::shareFailed);

    share->share(QString(kDeviceId), QStringLiteral("/tmp/kdc-test.txt"));

    QVERIFY(sharedSpy.wait(kTimeoutMs));
    QCOMPARE(sharedSpy.size(), 1);
    QCOMPARE(sharedSpy.constFirst().constFirst().toString(), QString(kDeviceId));
    QCOMPARE(failedSpy.size(), 0);

    QCOMPARE(plugin.calls, 1);
    QCOMPARE(plugin.lastUrls.constFirst(), QStringLiteral("file:///tmp/kdc-test.txt"));
}

void TestKdeConnectShare::errorReplyEmitsShareFailedWithTheDaemonMessage() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    plugin.reset();
    plugin.failNext = true;

    QSignalSpy sharedSpy(share.get(), &vast::KdeConnectShare::shared);
    QSignalSpy failedSpy(share.get(), &vast::KdeConnectShare::shareFailed);

    share->share(QString(kDeviceId), QStringLiteral("/tmp/kdc-test.txt"));

    QVERIFY(failedSpy.wait(kTimeoutMs));
    QCOMPARE(sharedSpy.size(), 0);
    QCOMPARE(failedSpy.constFirst().constFirst().toString(), QString(kDeviceId));
    QCOMPARE(failedSpy.constFirst().constLast().toString(), QStringLiteral("No such object path '%1'").arg(QString(kSharePath)));
}

void TestKdeConnectShare::emptyInputsFailWithoutTouchingTheBus() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    plugin.reset();
    QSignalSpy failedSpy(share.get(), &vast::KdeConnectShare::shareFailed);

    share->share(QString(), QStringLiteral("/tmp/kdc-test.txt"));
    share->share(QString(kDeviceId), QString());

    QCOMPARE(failedSpy.size(), 2);
    QCOMPARE(plugin.calls, 0);
}

QTEST_GUILESS_MAIN(TestKdeConnectShare)
#include "tst_kdeconnectshare.moc"
