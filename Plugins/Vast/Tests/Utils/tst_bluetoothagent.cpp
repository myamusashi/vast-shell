#include <qcoreapplication.h>
#include <qdbusconnection.h>
#include <qdbusmessage.h>
#include <qdbuspendingreply.h>
#include <qobject.h>
#include <qprocess.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include <functional>
#include <initializer_list>
#include <memory>
#include <optional>

#include <QDBusObjectPath>

#include "../../Utils/BluetoothAgentAdaptor.hpp"
#include "../../Utils/BluetoothAgentManager.hpp"

namespace {

    constexpr QLatin1StringView kAgentPath    = QLatin1StringView("/io/quickshell/BluetoothAgent");
    constexpr QLatin1StringView kDevicePath   = QLatin1StringView("/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF");
    constexpr QLatin1StringView kDevicePath2  = QLatin1StringView("/org/bluez/hci0/dev_11_22_33_44_55_66");
    constexpr QLatin1StringView kAgentIface   = QLatin1StringView("org.bluez.Agent1");
    constexpr QLatin1StringView kRejected     = QLatin1StringView("org.bluez.Error.Rejected");
    constexpr QLatin1StringView kBluezService = QLatin1StringView("org.bluez");

    const QString               kServiceUuid = QStringLiteral("0000110b-0000-1000-8000-00805f9b34fb");

    constexpr int               kTimeoutMs = 5000;
    constexpr int               kShortMs   = 1000; // a reply the code sends inline arrives in tens of ms

    // Counters are public members: moc rejects data members in Q_SLOTS.
    class FakeBlueZ : public QObject, public QDBusContext {
        Q_OBJECT
        Q_CLASSINFO("D-Bus Interface", "org.bluez.AgentManager1")

      public:
        int     registers       = 0;
        int     defaultRequests = 0;
        int     unregisters     = 0;
        QString lastAgentPath;

        // Error names to return from each call, consumed in order.
        QList<QByteArray> failWith;
        QList<QByteArray> requestDefaultFailWith;

        void              reset() {
            registers = defaultRequests = unregisters = 0;
            lastAgentPath.clear();
            failWith.clear();
            requestDefaultFailWith.clear();
        }

      public Q_SLOTS:
        void RegisterAgent(const QDBusObjectPath& path, const QString&) {
            ++registers;
            lastAgentPath = path.path();
            if (!failWith.isEmpty()) {
                const QByteArray name = failWith.takeFirst();
                sendErrorReply(QString::fromLatin1(name), QStringLiteral("scripted"));
            }
        }
        int RequestDefaultAgent(const QDBusObjectPath&) {
            ++defaultRequests;
            if (!requestDefaultFailWith.isEmpty()) {
                const QByteArray name = requestDefaultFailWith.takeFirst();
                sendErrorReply(QString::fromLatin1(name), QStringLiteral("scripted"));
                return -1;
            }
            return 0;
        }
        void UnregisterAgent(const QDBusObjectPath&) {
            ++unregisters;
        }
    };

    [[nodiscard]] QDBusMessage agentCall(QLatin1StringView method) {
        return QDBusMessage::createMethodCall(QString(kBluezService), QString(kAgentPath), QString(kAgentIface), QString(method));
    }

    [[nodiscard]] QDBusMessage pathCall(QLatin1StringView method, QLatin1StringView device, std::initializer_list<QVariant> extra = {}) {
        QDBusMessage call = agentCall(method);
        call << QVariant::fromValue(QDBusObjectPath(QString(device)));
        for (const QVariant& v : extra)
            call << v;
        return call;
    }

// A macro, not a function: QSKIP expands to `return;`, which in a helper
// would leave the slot to run on an empty connection.
// NOLINTNEXTLINE(cppcoreguidelines-macro-usage)
#define REQUIRE_BUS()                                                                                                                                                              \
    do {                                                                                                                                                                           \
        if (haveBus)                                                                                                                                                               \
            break;                                                                                                                                                                 \
        if (!qEnvironmentVariableIsSet("CI"))                                                                                                                                      \
            QSKIP("no private bus");                                                                                                                                               \
        QFAIL("CI: dbus-daemon is required but unavailable; the bus-backed tests would silently skip");                                                                            \
    } while (false)

} // namespace

class TestBluetoothAgent : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();
    void init();
    void cleanup();
    void cleanupTestCase();

    void deviceNameForPathDerivesALabelFromTheObjectPath();
    void deviceNameForPathPassesThroughANonDeviceTail();
    void deviceNameForPathOnAnEmptyPathIsEmpty();
    void adaptorExportsTheBluezAgent1Interface();
    void adaptorExportsTheSevenAgentMethodNames();
    void adaptorIgnoresCallsThatDidNotComeFromDBus();

    void registersItselfAsTheDefaultAgent();
    void unregistersTheAgentOnDestruction();
    void requestPinCodeMarksTheAgentBusyAndReportsTheName();
    void requestThenCompleteRoundTrips_data();
    void requestThenCompleteRoundTrips();
    void requestPinCodeDeliversTheSuppliedPinToTheCaller();
    void requestPasskeyDeliversTheSuppliedPasskey();
    void cancelToleratesAHandlerThatReplies();
    void registerAgentAlreadyExistsStillEndsActive();
    void requestDefaultAgentFailureLeavesTheAgentInactive();
    void cancelOrReleaseDrainsEveryPendingRequest_data();
    void cancelOrReleaseDrainsEveryPendingRequest();
    void aSecondRequestForTheSameDeviceRejectsTheFirst();
    void bluezGoingAwayCancelsPendingAndClearsActive();
    void bluezComingBackRegistersAgain();
    void bluetoothdStartingAfterTheShellStillRegistersTheAgent();
    void destroyingWithAPendingRequestRepliesRejectedInsteadOfAborting();
    void providePinCodeWithNoPendingRequestIsANoOp();
    void displayPasskeyEmitsWithoutStoringAPendingRequest();

  private:
    // std::optional: QDBusConnection has no default constructor. Named
    // connections persist until disconnectFromBus(), done in cleanupTestCase.
    [[nodiscard]] QDBusConnection& caller() {
        if (!caller_)
            caller_.emplace(QDBusConnection::connectToBus(address, QStringLiteral("caller")));
        return *caller_;
    }

    // A member so cleanup() always destroys it. The caller must await the
    // handshake: QTRY_VERIFY expands to `return;`.
    vast::BluetoothAgentManager& agent() {
        manager = std::make_unique<vast::BluetoothAgentManager>(nullptr, *bus);
        return *manager;
    }

    std::unique_ptr<vast::BluetoothAgentManager> manager;
    std::optional<QDBusConnection>               bus;
    std::optional<QDBusConnection>               caller_;
    QProcess                                     daemon;
    FakeBlueZ                                    bluez;
    QString                                      address;
    bool                                         haveBus{false};
    bool                                         bluezServiceUp{true};
};

void TestBluetoothAgent::initTestCase() {
    // Safety net: anything that reaches the system bus fails to connect here
    // rather than registering on the developer's real bluetoothd. Must run
    // before the first systemBus() call.
    qputenv("DBUS_SYSTEM_BUS_ADDRESS", "unix:path=/nonexistent-system-bus");

    daemon.start(QStringLiteral("dbus-daemon"), {QStringLiteral("--session"), QStringLiteral("--print-address"), QStringLiteral("--nofork")});
    if (!daemon.waitForStarted(kTimeoutMs))
        return;

    // readLine() on an empty buffer returns an empty line rather than blocking.
    if (daemon.waitForReadyRead(kTimeoutMs))
        address = QString::fromUtf8(daemon.readLine()).trimmed();
    if (address.isEmpty())
        return;

    bus.emplace(QDBusConnection::connectToBus(address, QStringLiteral("tst-bluetoothagent")));
    if (!bus->isConnected())
        return;

    // ExportAllSlots: FakeBlueZ declares its slots directly, not via an adaptor.
    if (!bus->registerObject(QStringLiteral("/org/bluez"), &bluez, QDBusConnection::ExportAllSlots))
        return;
    if (!bus->registerService(QString(kBluezService)))
        return;

    haveBus = true;
}

void TestBluetoothAgent::init() {
    bluez.reset();
    bluezServiceUp = true;
}

void TestBluetoothAgent::cleanup() {
    // If a slot left an entry pending, the destructor's reply loop runs here.
    manager.reset();

    // bluezGoingAway... unregisters it; restore here so later slots do not
    // depend on that slot finishing.
    if (!bluezServiceUp && bus) {
        if (bus->registerService(QString(kBluezService)))
            bluezServiceUp = true;
    }
}

void TestBluetoothAgent::cleanupTestCase() {
    manager.reset();
    if (bus) {
        bus->unregisterService(QString(kBluezService));
        bus->unregisterObject(QStringLiteral("/org/bluez"));
    }
    // Disconnect before the daemon goes away.
    QDBusConnection::disconnectFromBus(QStringLiteral("caller"));
    QDBusConnection::disconnectFromBus(QStringLiteral("tst-bluetoothagent"));
    if (daemon.state() != QProcess::NotRunning) {
        daemon.kill();
        daemon.waitForFinished(kTimeoutMs);
    }
}

void TestBluetoothAgent::deviceNameForPathDerivesALabelFromTheObjectPath() {
    QCOMPARE(vast::BluetoothAgentManager::deviceNameForPath(QString(kDevicePath)), QStringLiteral("AA:BB:CC:DD:EE:FF"));
}

void TestBluetoothAgent::deviceNameForPathPassesThroughANonDeviceTail() {
    QCOMPARE(vast::BluetoothAgentManager::deviceNameForPath(QStringLiteral("/org/bluez/hci0/someobject")), QStringLiteral("someobject"));
}

void TestBluetoothAgent::deviceNameForPathOnAnEmptyPathIsEmpty() {
    QVERIFY(vast::BluetoothAgentManager::deviceNameForPath(QString()).isEmpty());
}

void TestBluetoothAgent::adaptorExportsTheBluezAgent1Interface() {
    // QDBusAbstractAdaptor exports the literal C++ name, so a rename here
    // breaks pairing silently.
    const QMetaObject& meta  = vast::BluetoothAgentAdaptor::staticMetaObject;
    const int          index = meta.indexOfClassInfo("D-Bus Interface");
    QVERIFY(index >= 0);
    QCOMPARE(QString::fromLatin1(meta.classInfo(index).value()), QString(kAgentIface));
}

void TestBluetoothAgent::adaptorExportsTheSevenAgentMethodNames() {
    const QMetaObject& meta = vast::BluetoothAgentAdaptor::staticMetaObject;

    const QStringList  want{
        QStringLiteral("RequestPinCode"),   QStringLiteral("RequestPasskey"), QStringLiteral("DisplayPasskey"), QStringLiteral("RequestConfirmation"),
        QStringLiteral("AuthorizeService"), QStringLiteral("Cancel"),         QStringLiteral("Release"),
    };

    QStringList have;
    for (int i = 0; i < meta.methodCount(); ++i) {
        // A same-named signal would otherwise satisfy the lookup.
        if (meta.method(i).methodType() == QMetaMethod::Slot)
            have << QString::fromLatin1(meta.method(i).name());
    }

    for (const QString& name : want)
        QVERIFY2(have.contains(name), qPrintable(name));
}

void TestBluetoothAgent::adaptorIgnoresCallsThatDidNotComeFromDBus() {
    // In-process, so the adaptor's calledFromDBus guard must refuse it.
    REQUIRE_BUS();

    vast::BluetoothAgentManager mgr(nullptr, *bus);
    vast::BluetoothAgentAdaptor adaptor(&mgr);

    QCOMPARE(adaptor.RequestPinCode(QDBusObjectPath(QString(kDevicePath))), QString());
    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::registersItselfAsTheDefaultAgent() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    QCOMPARE(bluez.registers, 1);
    QCOMPARE(bluez.defaultRequests, 1);
    QCOMPARE(bluez.lastAgentPath, QString(kAgentPath));
}

void TestBluetoothAgent::unregistersTheAgentOnDestruction() {
    REQUIRE_BUS();

    agent();
    QTRY_VERIFY_WITH_TIMEOUT(manager->active(), kTimeoutMs);
    QCOMPARE(bluez.unregisters, 0);

    manager.reset();

    QTRY_COMPARE(bluez.unregisters, 1);
}

void TestBluetoothAgent::requestPinCodeMarksTheAgentBusyAndReportsTheName() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QSignalSpy busySpy(&mgr, &vast::BluetoothAgentManager::busyChanged);
    QSignalSpy nameSpy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    auto       reply = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);

    QTRY_VERIFY_WITH_TIMEOUT(nameSpy.count() == 1, kTimeoutMs);
    QVERIFY(mgr.busy());
    QCOMPARE(busySpy.count(), 1);
    QCOMPARE(nameSpy.at(0).at(1).toString(), QStringLiteral("AA:BB:CC:DD:EE:FF"));

    // Drained so cleanup() does not run the destructor's reply loop.
    mgr.providePinCode(QString(kDevicePath), QStringLiteral("4242"));
    QTRY_VERIFY_WITH_TIMEOUT(reply.isFinished(), kTimeoutMs);
    QVERIFY(!reply.isError());
}

void TestBluetoothAgent::requestThenCompleteRoundTrips_data() {
    QTest::addColumn<QByteArray>("method");
    QTest::addColumn<QVariantList>("extra");
    QTest::addColumn<bool>("accept");

    // The value-carrying replies have their own slots: QDBusPendingReply<T> is
    // templated on the reply signature. This table covers the void replies.
    QTest::newRow("confirm accept") << QByteArray("RequestConfirmation") << QVariantList{QVariant::fromValue<quint32>(123456)} << true;
    QTest::newRow("confirm reject") << QByteArray("RequestConfirmation") << QVariantList{QVariant::fromValue<quint32>(123456)} << false;
    QTest::newRow("authorize accept") << QByteArray("AuthorizeService") << QVariantList{kServiceUuid} << true;
    QTest::newRow("authorize reject") << QByteArray("AuthorizeService") << QVariantList{kServiceUuid} << false;
}

void TestBluetoothAgent::requestThenCompleteRoundTrips() {
    REQUIRE_BUS();

    QFETCH(QByteArray, method);
    QFETCH(QVariantList, extra);
    QFETCH(bool, accept);

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    QDBusMessage call = agentCall(QLatin1StringView(method));
    call << QVariant::fromValue(QDBusObjectPath(QString(kDevicePath)));
    for (const QVariant& v : std::as_const(extra))
        call << v;
    auto reply = std::make_unique<QDBusPendingCallWatcher>(caller().asyncCall(call, kTimeoutMs));

    // A typed spy per request signal; runtime signature lookup does not work.
    QSignalSpy  pinSpy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    QSignalSpy  passkeySpy(&mgr, &vast::BluetoothAgentManager::passkeyRequested);
    QSignalSpy  confirmSpy(&mgr, &vast::BluetoothAgentManager::confirmationRequested);
    QSignalSpy  authSpy(&mgr, &vast::BluetoothAgentManager::authorizationRequested);

    QSignalSpy* active = method == "RequestPinCode" ? &pinSpy : method == "RequestPasskey" ? &passkeySpy : method == "RequestConfirmation" ? &confirmSpy : &authSpy;

    QTRY_VERIFY_WITH_TIMEOUT(active->count() == 1, kTimeoutMs);
    QVERIFY(mgr.busy());

    if (method == "RequestConfirmation")
        mgr.confirmPairing(QString(kDevicePath), accept);
    else
        mgr.authorizeService(QString(kDevicePath), accept);

    QTRY_VERIFY_WITH_TIMEOUT(reply->isFinished(), kTimeoutMs);
    if (accept)
        QVERIFY2(!reply->isError(), qPrintable(reply->error().message()));
    else {
        QVERIFY(reply->isError());
        QCOMPARE(reply->error().name(), QString(kRejected));
    }
    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::requestPinCodeDeliversTheSuppliedPinToTheCaller() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QSignalSpy                 spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    QDBusPendingReply<QString> reply = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);

    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 1, kTimeoutMs);
    QVERIFY(mgr.busy());

    mgr.providePinCode(QString(kDevicePath), QStringLiteral("4242"));

    // waitForFinished() would block the thread that dispatches the reply.
    QTRY_VERIFY_WITH_TIMEOUT(reply.isFinished(), kTimeoutMs);
    QVERIFY2(!reply.isError(), qPrintable(reply.error().message()));
    QCOMPARE(reply.value(), QStringLiteral("4242"));
    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::requestPasskeyDeliversTheSuppliedPasskey() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QSignalSpy                 spy(&mgr, &vast::BluetoothAgentManager::passkeyRequested);
    QDBusPendingReply<quint32> reply = caller().asyncCall(pathCall(QLatin1StringView("RequestPasskey"), kDevicePath), kTimeoutMs);

    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 1, kTimeoutMs);
    QVERIFY(mgr.busy());

    mgr.providePasskey(QString(kDevicePath), 654321);

    QTRY_VERIFY_WITH_TIMEOUT(reply.isFinished(), kTimeoutMs);
    QVERIFY2(!reply.isError(), qPrintable(reply.error().message()));
    QCOMPARE(reply.value(), 654321u);
    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::cancelToleratesAHandlerThatReplies() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    const QStringList devices{QStringLiteral("/org/bluez/hci0/dev_AA"), QStringLiteral("/org/bluez/hci0/dev_BB"), QStringLiteral("/org/bluez/hci0/dev_CC"),
                              QStringLiteral("/org/bluez/hci0/dev_DD")};
    for (const QString& d : devices) {
        auto pending = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), QLatin1StringView(d.toUtf8().constData())), kTimeoutMs);
        Q_UNUSED(pending);
    }

    QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == devices.size(), kTimeoutMs);

    // A handler that replies from inside pairingCancelled, as a QML dialog
    // does. It targets the last device, so entries the loop has not reached
    // are removed underneath it.
    const QString victim = devices.last();
    QObject::connect(&mgr, &vast::BluetoothAgentManager::pairingCancelled, &mgr, [&mgr, victim](const QString&) { mgr.providePinCode(victim, QStringLiteral("1")); });

    QSignalSpy cancelled(&mgr, &vast::BluetoothAgentManager::pairingCancelled);
    mgr.handleCancel();

    // Every request must be cancelled.
    QCOMPARE(cancelled.count(), devices.size());
    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::registerAgentAlreadyExistsStillEndsActive() {
    REQUIRE_BUS();

    // AlreadyExists means the agent is already there.
    bluez.failWith.append("org.bluez.Error.AlreadyExists");

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QCOMPARE(bluez.registers, 1);
    QCOMPARE(bluez.defaultRequests, 1);
}

void TestBluetoothAgent::requestDefaultAgentFailureLeavesTheAgentInactive() {
    REQUIRE_BUS();

    // A non-default agent is never asked to handle a pairing.
    bluez.requestDefaultFailWith.append("org.bluez.Error.Failed");

    auto&      mgr = agent();
    QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::activeChanged);

    QTest::qWait(500);
    QVERIFY2(!mgr.active(), "active must stay false when RequestDefaultAgent failed");
    QVERIFY(spy.count() >= 1); // the state was published
    QCOMPARE(bluez.defaultRequests, 1);
}

void TestBluetoothAgent::cancelOrReleaseDrainsEveryPendingRequest_data() {
    QTest::addColumn<QByteArray>("method");
    QTest::addColumn<bool>("overBus");
    QTest::addColumn<bool>("deactivates");

    QTest::newRow("cancel direct") << QByteArray("Cancel") << false << false;
    QTest::newRow("cancel over bus") << QByteArray("Cancel") << true << false;
    QTest::newRow("release over bus") << QByteArray("Release") << true << true;
}

void TestBluetoothAgent::cancelOrReleaseDrainsEveryPendingRequest() {
    REQUIRE_BUS();

    QFETCH(QByteArray, method);
    QFETCH(bool, overBus);
    QFETCH(bool, deactivates);

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    // Two distinct devices; mPending is keyed by device path.
    auto       first  = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath2), kTimeoutMs);
    auto       second = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);

    QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 2, kTimeoutMs);
    QVERIFY(mgr.busy());

    if (overBus)
        caller().asyncCall(agentCall(QLatin1StringView(method)), kTimeoutMs);
    else
        mgr.handleCancel();

    QTRY_VERIFY_WITH_TIMEOUT(first.isFinished() && second.isFinished(), kTimeoutMs);
    QVERIFY(first.isError());
    QVERIFY(second.isError());
    QCOMPARE(first.error().name(), QString(kRejected));
    QCOMPARE(second.error().name(), QString(kRejected));
    QVERIFY(!mgr.busy());
    // Release also leaves the agent inactive until bluetoothd returns.
    QCOMPARE(mgr.active(), !deactivates);

    if (deactivates) {
        bluezServiceUp = bus->registerService(QString(kBluezService));
    }
}

void TestBluetoothAgent::aSecondRequestForTheSameDeviceRejectsTheFirst() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);

    auto       first  = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);
    auto       second = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);

    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 2, kTimeoutMs);

    // The displaced caller is rejected rather than left to time out.
    QTRY_VERIFY_WITH_TIMEOUT(first.isFinished(), kTimeoutMs);
    QVERIFY(first.isError());
    QCOMPARE(first.error().name(), QString(kRejected));
    QCOMPARE(first.error().message(), QStringLiteral("Superseded by a newer request"));
    QVERIFY(!second.isFinished());

    mgr.providePinCode(QString(kDevicePath), QStringLiteral("4242"));
    QTRY_VERIFY_WITH_TIMEOUT(second.isFinished(), kTimeoutMs);
    QVERIFY(!second.isError());
}

void TestBluetoothAgent::bluezGoingAwayCancelsPendingAndClearsActive() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);
    QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
    auto       pin = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kTimeoutMs);

    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 1, kTimeoutMs);
    QVERIFY(mgr.busy());

    // The reply assertion below guards a contract with no real consumer:
    // bluetoothd owns the org.bluez name and is also the only caller of
    // Agent1.*, so when the name loses its owner the waiter is already gone. Only
    // this test has a caller on a separate connection that outlives the name, so
    // the path is defensive rather than a live bug.
    QSignalSpy cancelledSpy(&mgr, &vast::BluetoothAgentManager::pairingCancelled);
    QVERIFY2(bus->unregisterService(QString(kBluezService)), "could not unregister org.bluez");
    bluezServiceUp = false;

    QTRY_VERIFY_WITH_TIMEOUT(!mgr.active(), kTimeoutMs);
    QCOMPARE(cancelledSpy.count(), 1);
    QCOMPARE(cancelledSpy.at(0).at(0).toString(), QString(kDevicePath));
    QVERIFY(!mgr.busy());

    QTRY_VERIFY_WITH_TIMEOUT(pin.isFinished(), kTimeoutMs);
    QVERIFY(pin.isError());
    QCOMPARE(pin.error().name(), QString(kRejected));
    QCOMPARE(pin.error().message(), QStringLiteral("bluetoothd went away"));
}

void TestBluetoothAgent::bluezComingBackRegistersAgain() {
    REQUIRE_BUS();

    agent();
    QTRY_VERIFY_WITH_TIMEOUT(manager->active(), kTimeoutMs);
    QCOMPARE(bluez.registers, 1);

    // A fresh manager against a bus where org.bluez is present registers again.
    agent();
    QTRY_VERIFY_WITH_TIMEOUT(manager->active(), kTimeoutMs);

    QCOMPARE(bluez.registers, 2);
    QVERIFY(bluez.defaultRequests >= 2);
}

void TestBluetoothAgent::bluetoothdStartingAfterTheShellStillRegistersTheAgent() {
    REQUIRE_BUS();

    // The production case: the shell comes up before bluetoothd.
    QVERIFY2(bus->unregisterService(QString(kBluezService)), "could not remove org.bluez to simulate a late bluetoothd");
    bluezServiceUp = false;

    agent();
    QVERIFY2(!manager->active(), "an agent built without bluetoothd must not claim to be active");
    QTest::qWait(200);
    QVERIFY(!manager->active());
    QCOMPARE(bluez.registers, 0);

    QVERIFY2(bus->registerService(QString(kBluezService)), "could not re-register org.bluez");
    bluezServiceUp = true;

    QTRY_VERIFY_WITH_TIMEOUT(manager->active(), kTimeoutMs);
    QCOMPARE(bluez.registers, 1);
    QCOMPARE(bluez.defaultRequests, 1);
}

void TestBluetoothAgent::destroyingWithAPendingRequestRepliesRejectedInsteadOfAborting() {
    REQUIRE_BUS();

    QDBusPendingReply<QString> reply;
    {
        // Local, not agent(): the member would outlive this block.
        vast::BluetoothAgentManager mgr(nullptr, *bus);
        QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

        QSignalSpy spy(&mgr, &vast::BluetoothAgentManager::pinCodeRequested);
        reply = caller().asyncCall(pathCall(QLatin1StringView("RequestPinCode"), kDevicePath), kShortMs);

        QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 1, kTimeoutMs);
        QVERIFY(mgr.busy());
        // Destroyed with the entry still pending: the destructor's reply loop
        // runs, which aborts libdbus if the message was never delivered.
    }

    QTRY_VERIFY_WITH_TIMEOUT(reply.isFinished(), kTimeoutMs);
    QVERIFY2(reply.isError(), "an unanswered request must not resolve successfully");
    QCOMPARE(reply.error().name(), QString(kRejected));
    QCOMPARE(reply.error().message(), QStringLiteral("Agent released"));
}

void TestBluetoothAgent::providePinCodeWithNoPendingRequestIsANoOp() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    // takePending misses, warns and returns false without sending anything.
    mgr.providePinCode(QStringLiteral("/org/bluez/hci0/dev_unknown"), QStringLiteral("1234"));

    QVERIFY(!mgr.busy());
}

void TestBluetoothAgent::displayPasskeyEmitsWithoutStoringAPendingRequest() {
    REQUIRE_BUS();

    auto& mgr = agent();
    QTRY_VERIFY_WITH_TIMEOUT(mgr.active(), kTimeoutMs);

    QDBusMessage call  = pathCall(QLatin1StringView("DisplayPasskey"), kDevicePath, {QVariant::fromValue<quint32>(654321), QVariant::fromValue<quint16>(2)});
    auto         reply = caller().asyncCall(call, kTimeoutMs);
    QSignalSpy   spy(&mgr, &vast::BluetoothAgentManager::passkeyDisplayed);

    QTRY_VERIFY_WITH_TIMEOUT(spy.count() == 1, kTimeoutMs);
    QCOMPARE(spy.at(0).at(1).toUInt(), 654321u);
    QCOMPARE(spy.at(0).at(2).toUInt(), 2u);

    // Informational only: BlueZ waits for no reply, so nothing is pending.
    QTRY_VERIFY_WITH_TIMEOUT(reply.isFinished(), kTimeoutMs);
    QVERIFY(!reply.isError());
    QVERIFY(!mgr.busy());
}

QTEST_GUILESS_MAIN(TestBluetoothAgent)
#include "tst_bluetoothagent.moc"
