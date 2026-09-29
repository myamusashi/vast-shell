#include <qobject.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include <memory>

#include "../../Brightness/BrightnessManager.hpp"

class TestBrightnessManager : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void cleanup();

    void displaysIsEmptyBeforeInitialize();
    void setBrightnessOnAnUnknownIdIsANoOp();
    void setBrightnessGroupIgnoresUnknownIds();
    void setBrightnessGroupAcceptsAnEmptyMap();
    void setBrightnessAllOnAnEmptyManagerIsANoOp();
    void profileRoundTripsThroughTheManager();
    void applyAnUnknownProfileIsANoOp();
    void saveProfileOverwritesTheSameName();

    void initializeEmitsDisplayListChangedExactlyOnce();
    void initializeEitherFindsDisplaysOrReportsFailure();

  private:
    // Every case runs against a manager whose initialize() was never called,
    // so mWorkers is empty and no hardware is touched.
    [[nodiscard]] vast::BrightnessManager& manager() {
        mManager = std::make_unique<vast::BrightnessManager>();
        return *mManager;
    }

    std::unique_ptr<vast::BrightnessManager> mManager;
};

void TestBrightnessManager::cleanup() {
    mManager.reset();
}

void TestBrightnessManager::displaysIsEmptyBeforeInitialize() {
    auto& m = manager();
    QVERIFY(m.displays().isEmpty());
}

void TestBrightnessManager::setBrightnessOnAnUnknownIdIsANoOp() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::brightnessChanged);

    m.setBrightness(QStringLiteral("ddc-999"), 50);

    QCOMPARE(spy.count(), 0);
}

void TestBrightnessManager::setBrightnessGroupIgnoresUnknownIds() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::brightnessChanged);

    // Qml/Services/Brightness.qml:117-120 builds this map by iterating
    // displays(), so a stale id is a routine input, not an edge case.
    m.setBrightnessGroup(QVariantMap{
        {QStringLiteral("ddc-999"), 10},
        {QStringLiteral("ddc-1000"), 20},
        {QStringLiteral("nonsense"), 30},
    });

    QCOMPARE(spy.count(), 0);
}

void TestBrightnessManager::setBrightnessGroupAcceptsAnEmptyMap() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::brightnessChanged);

    m.setBrightnessGroup(QVariantMap{});

    QCOMPARE(spy.count(), 0);
}

void TestBrightnessManager::setBrightnessAllOnAnEmptyManagerIsANoOp() {
    auto& m = manager();
    m.setBrightnessAll(70);
    QVERIFY(m.displays().isEmpty());
}

void TestBrightnessManager::profileRoundTripsThroughTheManager() {
    auto& m = manager();

    m.saveProfile(QStringLiteral("night"), QVariantMap{{QStringLiteral("ddc-1"), 20}});
    QCOMPARE(m.profileNames(), QStringList{QStringLiteral("night")});

    // applyProfile feeds the stored map straight into setBrightnessGroup, which
    // ignores the unknown id. It must not throw or emit on that path.
    QSignalSpy spy(&m, &vast::BrightnessManager::brightnessChanged);
    m.applyProfile(QStringLiteral("night"));
    QCOMPARE(spy.count(), 0);

    m.removeProfile(QStringLiteral("night"));
    QVERIFY(m.profileNames().isEmpty());
}

void TestBrightnessManager::applyAnUnknownProfileIsANoOp() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::brightnessChanged);

    m.applyProfile(QStringLiteral("never-saved"));

    QCOMPARE(spy.count(), 0);
    QVERIFY(m.profileNames().isEmpty());
}

void TestBrightnessManager::saveProfileOverwritesTheSameName() {
    auto& m = manager();

    m.saveProfile(QStringLiteral("p"), QVariantMap{{QStringLiteral("ddc-1"), 10}});
    m.saveProfile(QStringLiteral("p"), QVariantMap{{QStringLiteral("ddc-2"), 90}});

    QCOMPARE(m.profileNames(), QStringList{QStringLiteral("p")});
}

void TestBrightnessManager::initializeEmitsDisplayListChangedExactlyOnce() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::displayListChanged);

    m.initialize();

    // Emitted unconditionally, including on the no-displays path.
    QCOMPARE(spy.count(), 1);
}

void TestBrightnessManager::initializeEitherFindsDisplaysOrReportsFailure() {
    auto&      m = manager();
    QSignalSpy failSpy(&m, &vast::BrightnessManager::initializationFailed);

    m.initialize();

    // The one invariant that holds everywhere: this machine has
    // /sys/class/backlight/intel_backlight, CI has no backlight at all, and a
    // desktop may or may not have DDC monitors. Assert nothing about the count,
    // the ids, or the names -- only that failure and a non-empty list are
    // mutually exclusive.
    if (failSpy.count() > 0)
        QVERIFY2(m.displays().isEmpty(), "initializationFailed fired but displays() is not empty");
    else
        QVERIFY2(!m.displays().isEmpty(), "initialization succeeded but no displays were found");
}

QTEST_GUILESS_MAIN(TestBrightnessManager)
#include "tst_brightnessmanager.moc"
