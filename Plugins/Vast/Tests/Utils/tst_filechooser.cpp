#include <qcoreapplication.h>
#include <qdbusconnection.h>
#include <qdbuscontext.h>
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

#include "../../Utils/FileChooser.hpp"

namespace {

    constexpr QLatin1StringView kPortalService  = QLatin1StringView("org.freedesktop.portal.Desktop");
    constexpr QLatin1StringView kPortalPath     = QLatin1StringView("/org/freedesktop/portal/desktop");
    constexpr QLatin1StringView kChooserIface   = QLatin1StringView("org.freedesktop.portal.FileChooser");
    constexpr QLatin1StringView kRequestIface   = QLatin1StringView("org.freedesktop.portal.Request");
    constexpr QLatin1StringView kResponseMember = QLatin1StringView("Response");

    constexpr int               kTimeoutMs = 5000;
    constexpr int               kQuietMs   = 300;

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

class FakePortalFileChooser : public QObject, public QDBusContext {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.portal.FileChooser")

  public:
    int         calls{0};
    bool        failNext{false};
    bool        returnEmptyPath{false};
    QString     lastParentWindow;
    QString     lastTitle;
    QVariantMap lastOptions;
    QString     lastToken;
    QString     lastRequestPath;

    void        reset() {
        calls           = 0;
        failNext        = false;
        returnEmptyPath = false;
        lastParentWindow.clear();
        lastTitle.clear();
        lastOptions.clear();
        lastToken.clear();
        lastRequestPath.clear();
    }

  public Q_SLOTS:
    QDBusObjectPath OpenFile(const QString& parentWindow, const QString& title, const QVariantMap& options) {
        ++calls;
        lastParentWindow = parentWindow;
        lastTitle        = title;
        lastOptions      = options;

        if (failNext) {
            sendErrorReply(QStringLiteral("org.freedesktop.portal.Error.Failed"), QStringLiteral("Portal backend unavailable"));
            Q_EMIT openFileCalled(QString());
            return QDBusObjectPath();
        }
        if (returnEmptyPath) {
            Q_EMIT openFileCalled(QStringLiteral("/"));
            return QDBusObjectPath(QStringLiteral("/"));
        }

        const QString token = options.value(QStringLiteral("handle_token")).toString();
        lastToken           = token;

        QString sender = message().service();
        if (sender.startsWith(QLatin1Char(':')))
            sender.remove(0, 1);
        sender.replace(QLatin1Char('.'), QLatin1Char('_'));

        lastRequestPath = QStringLiteral("/org/freedesktop/portal/desktop/request/%1/%2").arg(sender, token);
        Q_EMIT openFileCalled(lastRequestPath);
        return QDBusObjectPath(lastRequestPath);
    }

  Q_SIGNALS:
    void openFileCalled(const QString& requestPath);
};

class TestFileChooser : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void cleanupTestCase();
    void cleanup();

    void buildOpenFileMessageIncludesTokenTitleAndFilters();
    void buildOpenFileMessageSetsDirectoryFlagAndOmitsFiltersInFolderMode();
    void urisToLocalPathsDecodesPercentEncodedFileUris();

    void successfulPortalResponseEmitsFileSelected();
    void cancelledPortalResponseEmitsCancelledWithoutFailed();
    void otherTokenResponsePathIsIgnored();
    void portalMethodErrorEmitsFailedForFallback();
    void reentrantOpenWhileBusyIsIgnored();
    void invalidRequestPathReplyEmitsFailedForFallback();

  private:
    void                               sendResponse(const QString& requestPath, quint32 responseCode, const QVariantMap& results);

    QProcess                           daemon;
    std::unique_ptr<QTemporaryDir>     busDir;
    std::optional<QDBusConnection>     serviceBus;
    std::optional<QDBusConnection>     clientBus;
    QString                            address;
    FakePortalFileChooser              portal;
    std::unique_ptr<vast::FileChooser> chooser;
    QString                            busFailure;
    bool                               haveBus{false};
};

void TestFileChooser::initTestCase() {
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

    serviceBus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-filechooser-service")));
    if (!serviceBus->isConnected()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("connectToBus(service)"));
        return;
    }

    if (!serviceBus->registerObject(QString(kPortalPath), &portal, QDBusConnection::ExportAllSlots)) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("registerObject"));
        return;
    }

    if (!serviceBus->registerService(QString(kPortalService))) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("registerService %1").arg(QString(kPortalService)));
        return;
    }

    clientBus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-filechooser-client")));
    if (!clientBus->isConnected()) {
        busFailure = describeBusFailure(daemon, address, QStringLiteral("connectToBus(client)"));
        return;
    }

    chooser = std::make_unique<vast::FileChooser>(nullptr, *clientBus);
    haveBus = true;
}

void TestFileChooser::cleanupTestCase() {
    chooser.reset();
    if (serviceBus) {
        serviceBus->unregisterService(QString(kPortalService));
        serviceBus->unregisterObject(QString(kPortalPath));
    }
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-filechooser-client"));
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-filechooser-service"));
    if (daemon.state() != QProcess::NotRunning) {
        daemon.kill();
        daemon.waitForFinished(kTimeoutMs);
    }
}
void TestFileChooser::cleanup() {
    portal.reset();
    if (chooser) {
        chooser->setTitle({});
        chooser->setNameFilters({QStringLiteral("*")});
        chooser->setSelectFolder(false);
    }
}

void TestFileChooser::sendResponse(const QString& requestPath, quint32 responseCode, const QVariantMap& results) {
    QDBusMessage msg = QDBusMessage::createSignal(requestPath, QString(kRequestIface), QString(kResponseMember));
    msg << responseCode << results;
    QVERIFY(serviceBus->send(msg));
}

void TestFileChooser::buildOpenFileMessageIncludesTokenTitleAndFilters() {
    const QStringList  nameFilters{QStringLiteral("*.json"), QStringLiteral("*.js")};
    const QDBusMessage message = vast::FileChooser::buildOpenFileMessage(QStringLiteral("Custom Title"), QStringLiteral("token_123"), false, nameFilters);

    QCOMPARE(message.service(), QString(kPortalService));
    QCOMPARE(message.path(), QString(kPortalPath));
    QCOMPARE(message.interface(), QString(kChooserIface));
    QCOMPARE(message.member(), QStringLiteral("OpenFile"));
    QCOMPARE(message.type(), QDBusMessage::MethodCallMessage);

    const QList<QVariant> args = message.arguments();
    QCOMPARE(args.size(), 3);
    QCOMPARE(args.at(0).toString(), QString());
    QCOMPARE(args.at(1).toString(), QStringLiteral("Custom Title"));

    const QVariantMap options = args.at(2).toMap();
    QCOMPARE(options.value(QStringLiteral("handle_token")).toString(), QStringLiteral("token_123"));
    QCOMPARE(options.value(QStringLiteral("modal")).toBool(), true);
    QVERIFY(!options.contains(QStringLiteral("directory")));
    QVERIFY(options.contains(QStringLiteral("filters")));

    const auto filters = qvariant_cast<vast::PortalFilterList>(options.value(QStringLiteral("filters")));
    QCOMPARE(filters.size(), 2);
    QCOMPARE(filters.at(0).rules.size(), 2);
    QCOMPARE(filters.at(0).rules.at(0).pattern, QStringLiteral("*.json"));
    QCOMPARE(filters.at(0).rules.at(1).pattern, QStringLiteral("*.js"));
    QCOMPARE(filters.at(1).label, QStringLiteral("All Files"));
    QCOMPARE(filters.at(1).rules.at(0).pattern, QStringLiteral("*"));
}

void TestFileChooser::buildOpenFileMessageSetsDirectoryFlagAndOmitsFiltersInFolderMode() {
    const QStringList  nameFilters{QStringLiteral("*.png")};
    const QDBusMessage message = vast::FileChooser::buildOpenFileMessage(QString(), QStringLiteral("token_dir"), true, nameFilters);

    QCOMPARE(message.type(), QDBusMessage::MethodCallMessage);
    const QList<QVariant> args = message.arguments();
    QCOMPARE(args.at(1).toString(), QStringLiteral("Select Folder"));

    const QVariantMap options = args.at(2).toMap();
    QCOMPARE(options.value(QStringLiteral("directory")).toBool(), true);
    QVERIFY(!options.contains(QStringLiteral("filters")));
}

void TestFileChooser::urisToLocalPathsDecodesPercentEncodedFileUris() {
    const QStringList uris{QStringLiteral("file:///home/myamusashi/My%20Wallpaper.png"), QStringLiteral("file:///home/myamusashi/WorkspaceView.qml"),
                           QStringLiteral("/home/myamusashi/direct_path.txt")};

    const QStringList localPaths = vast::FileChooser::urisToLocalPaths(uris);
    QCOMPARE(localPaths.size(), 3);
    QCOMPARE(localPaths.at(0), QStringLiteral("/home/myamusashi/My Wallpaper.png"));
    QCOMPARE(localPaths.at(1), QStringLiteral("/home/myamusashi/WorkspaceView.qml"));
    QCOMPARE(localPaths.at(2), QStringLiteral("/home/myamusashi/direct_path.txt"));
}

void TestFileChooser::successfulPortalResponseEmitsFileSelected() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    portal.reset();
    chooser->setTitle(QStringLiteral("Pick File"));
    chooser->setNameFilters({QStringLiteral("*.qml")});
    chooser->setSelectFolder(false);

    QSignalSpy portalSpy(&portal, &FakePortalFileChooser::openFileCalled);
    QSignalSpy fileSpy(chooser.get(), &vast::FileChooser::fileSelected);
    QSignalSpy filesSpy(chooser.get(), &vast::FileChooser::filesSelected);
    QSignalSpy busySpy(chooser.get(), &vast::FileChooser::busyChanged);
    QSignalSpy failedSpy(chooser.get(), &vast::FileChooser::failed);

    chooser->open();
    QVERIFY(chooser->busy());
    QVERIFY(portalSpy.wait(kTimeoutMs));
    QCOMPARE(portal.calls, 1);
    const QString requestPath = portal.lastRequestPath;
    QVERIFY(!requestPath.isEmpty());

    QVariantMap results;
    results.insert(QStringLiteral("uris"), QStringList{QStringLiteral("file:///home/myamusashi/WorkspaceView.qml")});
    sendResponse(requestPath, 0U, results);

    QVERIFY(fileSpy.wait(kTimeoutMs));
    QCOMPARE(fileSpy.size(), 1);
    QCOMPARE(fileSpy.constFirst().constFirst().toString(), QStringLiteral("/home/myamusashi/WorkspaceView.qml"));

    QCOMPARE(filesSpy.size(), 1);
    QCOMPARE(filesSpy.constFirst().constFirst().toStringList(), QStringList{QStringLiteral("/home/myamusashi/WorkspaceView.qml")});

    QCOMPARE(failedSpy.size(), 0);
    QVERIFY(!chooser->busy());
}

void TestFileChooser::cancelledPortalResponseEmitsCancelledWithoutFailed() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    QSignalSpy portalSpy(&portal, &FakePortalFileChooser::openFileCalled);
    QSignalSpy cancelSpy(chooser.get(), &vast::FileChooser::cancelled);
    QSignalSpy fileSpy(chooser.get(), &vast::FileChooser::fileSelected);
    QSignalSpy failedSpy(chooser.get(), &vast::FileChooser::failed);

    chooser->open();
    QVERIFY(chooser->busy());
    QVERIFY(portalSpy.wait(kTimeoutMs));
    const QString requestPath = portal.lastRequestPath;
    sendResponse(requestPath, 1U, {});

    QVERIFY(cancelSpy.wait(kTimeoutMs));
    QCOMPARE(cancelSpy.size(), 1);
    QCOMPARE(fileSpy.size(), 0);
    QCOMPARE(failedSpy.size(), 0);
    QVERIFY(!chooser->busy());
}

void TestFileChooser::otherTokenResponsePathIsIgnored() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    QSignalSpy portalSpy(&portal, &FakePortalFileChooser::openFileCalled);
    QSignalSpy cancelSpy(chooser.get(), &vast::FileChooser::cancelled);
    QSignalSpy fileSpy(chooser.get(), &vast::FileChooser::fileSelected);

    chooser->open();
    QVERIFY(chooser->busy());
    QVERIFY(portalSpy.wait(kTimeoutMs));
    sendResponse(QStringLiteral("/org/freedesktop/portal/desktop/request/caller/unrelated_token"), 0U,
                 {{QStringLiteral("uris"), QStringList{QStringLiteral("file:///tmp/other.txt")}}});

    QVERIFY(!fileSpy.wait(kQuietMs));
    QCOMPARE(fileSpy.size(), 0);
    QCOMPARE(cancelSpy.size(), 0);
    QVERIFY(chooser->busy());

    // Resolve real token to clean up
    sendResponse(portal.lastRequestPath, 1U, {});
    QVERIFY(cancelSpy.wait(kTimeoutMs));
    QVERIFY(!chooser->busy());
}

void TestFileChooser::portalMethodErrorEmitsFailedForFallback() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    portal.reset();
    portal.failNext = true;

    QSignalSpy failedSpy(chooser.get(), &vast::FileChooser::failed);
    QSignalSpy cancelSpy(chooser.get(), &vast::FileChooser::cancelled);

    chooser->open();

    QVERIFY(failedSpy.wait(kTimeoutMs));
    QCOMPARE(failedSpy.size(), 1);
    QCOMPARE(failedSpy.constFirst().constFirst().toString(), QStringLiteral("Portal backend unavailable"));
    QCOMPARE(cancelSpy.size(), 0);
    QVERIFY(!chooser->busy());
}
void TestFileChooser::reentrantOpenWhileBusyIsIgnored() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    portal.reset();
    QSignalSpy portalSpy(&portal, &FakePortalFileChooser::openFileCalled);
    QSignalSpy cancelSpy(chooser.get(), &vast::FileChooser::cancelled);

    chooser->open();
    QVERIFY(chooser->busy());
    QVERIFY(portalSpy.wait(kTimeoutMs));
    QCOMPARE(portal.calls, 1);

    // Second open while still busy must be a no-op
    chooser->open();
    QCOMPARE(portal.calls, 1);

    sendResponse(portal.lastRequestPath, 1U, {});
    QVERIFY(cancelSpy.wait(kTimeoutMs));
    QVERIFY(!chooser->busy());
}

void TestFileChooser::invalidRequestPathReplyEmitsFailedForFallback() {
    if (!haveBus)
        QSKIP(qPrintable(QStringLiteral("no private bus: %1").arg(busFailure)));

    portal.reset();
    portal.returnEmptyPath = true;

    QSignalSpy failedSpy(chooser.get(), &vast::FileChooser::failed);

    chooser->open();

    QVERIFY(failedSpy.wait(kTimeoutMs));
    QCOMPARE(failedSpy.size(), 1);
    QCOMPARE(failedSpy.constFirst().constFirst().toString(), QStringLiteral("Portal returned an invalid request path"));
    QVERIFY(!chooser->busy());
}

QTEST_GUILESS_MAIN(TestFileChooser)
#include "tst_filechooser.moc"
