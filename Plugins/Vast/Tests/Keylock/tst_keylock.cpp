#include <qmetaobject.h>
#include <qmetatype.h>
#include <qstring.h>
#include <qtest.h>

#include <linux/input-event-codes.h>
#include <linux/input.h>

#include "../../Keylock/KeyEventDecoder.hpp"
#include "../../Keylock/KeylockState.hpp"

namespace {

    // input_event is the kernel ABI; the tests build the record a driver delivers.
    [[nodiscard]] struct input_event ev(uint16_t type, uint16_t code, int32_t value) {
        struct input_event e{};
        e.type  = type;
        e.code  = code;
        e.value = value;
        return e;
    }

    using Change = vast::KeyEventDecoder::Change;

} // namespace

class TestKeylock : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    // LED mode: the driver is authoritative.
    void ledEventSetsCapsLock();
    void ledEventClearsCapsLock();
    void ledEventWithTheSameValueReportsNoChange();
    void ledEventForNumLock();
    void ledModeIgnoresKeyEvents();
    void ledModeIgnoresUnrelatedLedCodes();

    // Key mode: the press is all we have, so it toggles.
    void keyEventTogglesCapsLock();
    void aSecondPressTogglesBack();
    void keyEventForNumLockTogglesOnlyNumLock();
    void keyModeTogglesEvenWhenTheStateDisagrees();
    void keyModeIgnoresLedEvents();
    void keyModeIgnoresKeyRelease();
    void keyModeIgnoresAutoRepeat();
    void keyModeIgnoresUnrelatedKeys();
    void nonStateEventsAreIgnoredInBothModes();
    void setStateSeedsBothLocks();

    void keylockPropertiesMatchTheQmlSingleton();
};

void TestKeylock::ledEventSetsCapsLock() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 1), true), Change::CapsLock);
    QVERIFY(d.capsLock());
    QVERIFY(!d.numLock());
}

void TestKeylock::ledEventClearsCapsLock() {
    vast::KeyEventDecoder d;
    d.setState(true, false);

    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 0), true), Change::CapsLock);
    // The only path that can turn a lock off.
    QVERIFY(!d.capsLock());
}

void TestKeylock::ledEventWithTheSameValueReportsNoChange() {
    vast::KeyEventDecoder d;
    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 1), true), Change::CapsLock);
    QVERIFY(d.capsLock());

    // A repeated LED value must not report a change, or the OSD flickers.
    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 1), true), Change::None);
    QVERIFY(d.capsLock());
}

void TestKeylock::ledEventForNumLock() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_LED, LED_NUML, 1), true), Change::NumLock);
    QVERIFY(d.numLock());
    QVERIFY(!d.capsLock());
}

void TestKeylock::ledModeIgnoresKeyEvents() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), true), Change::None);
    QVERIFY(!d.capsLock());
}

void TestKeylock::ledModeIgnoresUnrelatedLedCodes() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_LED, LED_MUTE, 1), true), Change::None);
    QVERIFY(!d.capsLock());
    QVERIFY(!d.numLock());
}

void TestKeylock::keyEventTogglesCapsLock() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), false), Change::CapsLock);
    QVERIFY(d.capsLock());
}

void TestKeylock::aSecondPressTogglesBack() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), false), Change::CapsLock);
    QVERIFY(d.capsLock());
    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), false), Change::CapsLock);
    QVERIFY(!d.capsLock());
}

void TestKeylock::keyEventForNumLockTogglesOnlyNumLock() {
    vast::KeyEventDecoder d;
    d.setState(true, false);

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_NUMLOCK, 1), false), Change::NumLock);
    QVERIFY(d.numLock());
    QVERIFY(d.capsLock()); // untouched
}

void TestKeylock::keyModeTogglesEvenWhenTheStateDisagrees() {
    vast::KeyEventDecoder d;
    d.setState(true, false);

    // Key mode toggles unconditionally and may drift; not a defect to fix.
    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), false), Change::CapsLock);
    QVERIFY(!d.capsLock());
}

void TestKeylock::keyModeIgnoresLedEvents() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 1), false), Change::None);
    QVERIFY(!d.capsLock());
}

void TestKeylock::keyModeIgnoresKeyRelease() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 0), false), Change::None);
    QVERIFY(!d.capsLock());
}

void TestKeylock::keyModeIgnoresAutoRepeat() {
    vast::KeyEventDecoder d;
    d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 1), false);
    QVERIFY(d.capsLock());

    // Auto-repeat must not flap the indicator.
    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_CAPSLOCK, 2), false), Change::None);
    QVERIFY(d.capsLock());
}

void TestKeylock::keyModeIgnoresUnrelatedKeys() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_A, 1), false), Change::None);
    QCOMPARE(d.applyEvent(ev(EV_KEY, KEY_ESC, 1), false), Change::None);
    QVERIFY(!d.capsLock());
    QVERIFY(!d.numLock());
}

void TestKeylock::nonStateEventsAreIgnoredInBothModes() {
    vast::KeyEventDecoder d;

    QCOMPARE(d.applyEvent(ev(EV_SYN, SYN_REPORT, 0), true), Change::None);
    QCOMPARE(d.applyEvent(ev(EV_SYN, SYN_REPORT, 0), false), Change::None);
    QCOMPARE(d.applyEvent(ev(EV_MSC, MSC_SCAN, 1), true), Change::None);
    QCOMPARE(d.applyEvent(ev(EV_MSC, MSC_SCAN, 1), false), Change::None);
    QVERIFY(!d.capsLock());
    QVERIFY(!d.numLock());
}

void TestKeylock::setStateSeedsBothLocks() {
    // The readInitialState entry point; a matching LED event then reports no change.
    vast::KeyEventDecoder d;
    d.setState(true, true);

    QVERIFY(d.capsLock());
    QVERIFY(d.numLock());
    QCOMPARE(d.applyEvent(ev(EV_LED, LED_CAPSL, 1), true), Change::None);
    QCOMPARE(d.applyEvent(ev(EV_LED, LED_NUML, 1), true), Change::None);
}

void TestKeylock::keylockPropertiesMatchTheQmlSingleton() {
    // A metaObject walk, so no Keylock is constructed. KeylockState.qml:9-10,
    // OSD.qml:73,79 and CapsLockPopup.qml:82 bind these by name.
    const QMetaObject* const meta = &vast::Keylock::staticMetaObject;

    for (const char* name : {"capsLock", "numLock"}) {
        const int idx = meta->indexOfProperty(name);
        QVERIFY2(idx >= 0, name);

        const QMetaProperty prop = meta->property(idx);
        QCOMPARE(prop.typeId(), static_cast<int>(QMetaType::Bool));
        QCOMPARE(QString::fromLatin1(prop.notifySignal().name()), QString::fromLatin1(strcmp(name, "capsLock") == 0 ? "capsLockChanged" : "numLockChanged"));
    }
}

QTEST_GUILESS_MAIN(TestKeylock)
#include "tst_keylock.moc"
