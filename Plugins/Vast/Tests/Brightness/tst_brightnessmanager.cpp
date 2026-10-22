#include <qobject.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include <filesystem>
#include <memory>
#include <utility>

#include "../../Brightness/BrightnessManager.hpp"

namespace {

    // A synthetic display, so the snapshot semantics can be exercised without
    // a DDC monitor and without a sysfs backlight device.
    [[nodiscard]] std::shared_ptr<vast::DisplayWorker> fakeWorker(const QString& id, int brightness) {
        // clang-format off
        vast::DisplayMeta meta{
                                     .id            = id,
                                     .name          = QStringLiteral("Internal: %1").arg(id),
                                     .type          = vast::DisplayType::Backlight,
                                     .backlightPath = std::filesystem::path("/sys/class/backlight") / id.toStdString(),
                                     .ddc           = {},
        };
        // clang-format on

        return std::make_shared<vast::DisplayWorker>(std::move(meta), brightness);
    }

} // namespace

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

    void publishDisplaysReplacesTheSnapshot();
    void publishDisplaysWithAnEmptyMapClearsTheSnapshot();

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

    // The scan runs on the job thread and the snapshot is published back on
    // the UI thread, so the signal is not immediate.
    QVERIFY(spy.wait(10000));

    // Emitted unconditionally, including on the no-displays path.
    QCOMPARE(spy.count(), 1);
}

void TestBrightnessManager::initializeEitherFindsDisplaysOrReportsFailure() {
    auto&      m = manager();
    QSignalSpy failSpy(&m, &vast::BrightnessManager::initializationFailed);
    QSignalSpy listSpy(&m, &vast::BrightnessManager::displayListChanged);

    m.initialize();

    // The failure is reported before the snapshot is published, so waiting for
    // the list change is enough to see both.
    QVERIFY(listSpy.wait(10000));

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

void TestBrightnessManager::publishDisplaysReplacesTheSnapshot() {
    auto&      m = manager();
    QSignalSpy spy(&m, &vast::BrightnessManager::displayListChanged);

    m.publishDisplays(vast::BrightnessManager::WorkerMap{
        {QStringLiteral("intel_backlight"), fakeWorker(QStringLiteral("intel_backlight"), 40)},
    });

    QCOMPARE(spy.count(), 1);
    QCOMPARE(m.displays().size(), 1);

    // A rescan replaces the snapshot instead of merging into it: the display
    // that is gone must not survive the scan, and the display that appeared
    // must be visible.
    m.publishDisplays(vast::BrightnessManager::WorkerMap{
        {QStringLiteral("ddc-1"), fakeWorker(QStringLiteral("ddc-1"), 70)},
    });

    QCOMPARE(spy.count(), 2);
    QCOMPARE(m.displays().size(), 1);

    const auto entry = m.displays().first().toMap();
    QCOMPARE(entry.value(QStringLiteral("id")).toString(), QStringLiteral("ddc-1"));
    QCOMPARE(entry.value(QStringLiteral("brightness")).toInt(), 70);
}

void TestBrightnessManager::publishDisplaysWithAnEmptyMapClearsTheSnapshot() {
    auto& m = manager();

    m.publishDisplays(vast::BrightnessManager::WorkerMap{
        {QStringLiteral("intel_backlight"), fakeWorker(QStringLiteral("intel_backlight"), 40)},
    });
    QVERIFY(!m.displays().isEmpty());

    // Every display was unplugged: the snapshot is empty afterwards.
    m.publishDisplays({});

    QVERIFY(m.displays().isEmpty());
}

QTEST_GUILESS_MAIN(TestBrightnessManager)
#include "tst_brightnessmanager.moc"
