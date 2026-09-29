#include <qfile.h>
#include <qfileinfo.h>
#include <qstring.h>
#include <qtest.h>
#include <qtemporarydir.h>

#include <filesystem>
#include <fstream>
#include <memory>
#include <string>

#include <unistd.h>

#include "../../Brightness/BrightnessManager.hpp"

namespace {

    vast::DisplayMeta backlightMeta(const QString& id, const std::filesystem::path& root) {
        return vast::DisplayMeta{
            .id            = id,
            .name          = QStringLiteral("Internal: %1").arg(id),
            .type          = vast::DisplayType::Backlight,
            .backlightPath = root,
            .ddcHandle     = {},
        };
    }

    void writeMaxBrightness(const std::filesystem::path& root, int max) {
        std::ofstream stream(root / "max_brightness");
        stream << max;
    }

    void writeRawBrightness(const std::filesystem::path& root, int value) {
        std::ofstream stream(root / "brightness");
        stream << value;
    }

    [[nodiscard]] QString readRawBrightness(const std::filesystem::path& root) {
        std::ifstream stream(root / "brightness");
        std::string   out;
        stream >> out;
        return QString::fromStdString(out);
    }

} // namespace

class TestBrightnessDisplay : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void newWorkerHasNoPendingValue();
    void storePendingMakesItVisible();
    void takePendingClearsAndReturns();
    void storePendingOverwritesTheEarlierValue();
    void beginWriteIsExclusiveAndEndWriteReleasesIt();
    void beginWriteDoesNotDisturbAPendingValue();
    void currentBrightnessTracksSetCalls();
    void metaIsExposedByReference();

    void clampPercentClampsBelowRange();
    void clampPercentClampsAboveRange();
    void clampPercentPassesThroughInRange();

    void backlightRoundTripsPercent();
    void readBacklightScalesAgainstMaxBrightness();
    void writeBacklightScalesByTheDeviceMaxNotOneHundred();
    void readBacklightFailsOnAMissingDirectory();
    void readBacklightFailsWhenMaxBrightnessIsZero();
    void readBacklightFailsWhenTheDirectoryHasNoFiles();
    void writeBacklightFailsOnAMissingDirectory();
    void writeBacklightFailsWhenBrightnessIsNotWritable();

  private:
    // A fresh sysfs-shaped directory per case, so one case's max_brightness
    // cannot leak into the next.
    [[nodiscard]] std::filesystem::path freshRoot(const char* name) {
        const std::filesystem::path dir = mDir->path().toStdString() + "/" + name;
        std::filesystem::create_directories(dir);
        return dir;
    }

    std::unique_ptr<QTemporaryDir> mDir;
    bool                           mRoot{false};
};

void TestBrightnessDisplay::initTestCase() {
    mDir = std::make_unique<QTemporaryDir>();
    QVERIFY(mDir->isValid());
    // root bypasses permission bits, so the unwritable-brightness case cannot
    // be reproduced; that slot skips itself rather than silently passing.
    mRoot = ::geteuid() == 0;
}

void TestBrightnessDisplay::newWorkerHasNoPendingValue() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("intel_backlight"), "/tmp"), 55);

    QVERIFY(!worker.hasPending());
    QCOMPARE(worker.currentBrightness(), 55);
    QCOMPARE(worker.meta().id, QStringLiteral("intel_backlight"));
}

void TestBrightnessDisplay::storePendingMakesItVisible() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 0);

    worker.storePending(40);

    QVERIFY(worker.hasPending());
}

void TestBrightnessDisplay::takePendingClearsAndReturns() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 0);

    worker.storePending(40);
    QCOMPARE(worker.takePending(), 40);
    QVERIFY(!worker.hasPending());
    // A second take drains nothing; it must not resurface a stale value.
    QCOMPARE(worker.takePending(), -1);
}

void TestBrightnessDisplay::storePendingOverwritesTheEarlierValue() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 0);

    // The point of coalescing: a slider drag ends in one write carrying the
    // latest value, not a queue of every intermediate position.
    worker.storePending(30);
    worker.storePending(50);

    QCOMPARE(worker.takePending(), 50);
}

void TestBrightnessDisplay::beginWriteIsExclusiveAndEndWriteReleasesIt() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 0);

    QVERIFY(worker.beginWrite());
    QVERIFY(!worker.beginWrite());
    worker.endWrite();
    QVERIFY(worker.beginWrite());
}

void TestBrightnessDisplay::beginWriteDoesNotDisturbAPendingValue() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 0);

    // The in-flight flag and the pending slot are independent; conflating them
    // would drop the user's final slider position.
    worker.storePending(60);
    QVERIFY(worker.beginWrite());
    worker.endWrite();

    QCOMPARE(worker.takePending(), 60);
}

void TestBrightnessDisplay::currentBrightnessTracksSetCalls() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("d"), "/tmp"), 10);

    worker.setCurrentBrightness(77);

    QCOMPARE(worker.currentBrightness(), 77);
}

void TestBrightnessDisplay::metaIsExposedByReference() {
    vast::DisplayWorker worker(backlightMeta(QStringLiteral("ddc-7"), "/tmp"), 0);

    // dispatchWrite holds this reference across the job post, so meta() must
    // hand back the worker's own member rather than a per-call temporary: two
    // calls have to yield the same address. It is the worker's own copy -- the
    // ctor takes DisplayMeta by value -- which is the point.
    const vast::DisplayMeta* first  = &worker.meta();
    const vast::DisplayMeta* second = &worker.meta();
    QCOMPARE(first, second);

    QCOMPARE(worker.meta().id, QStringLiteral("ddc-7"));
    QCOMPARE(worker.meta().name, QStringLiteral("Internal: ddc-7"));
    QCOMPARE(worker.meta().type, vast::DisplayType::Backlight);
    QCOMPARE(worker.meta().backlightPath, std::filesystem::path("/tmp"));
    QVERIFY(!worker.meta().ddcHandle.valid());
}

void TestBrightnessDisplay::clampPercentClampsBelowRange() {
    QCOMPARE(vast::BrightnessManager::clampPercent(-1), 0);
    QCOMPARE(vast::BrightnessManager::clampPercent(-1000), 0);
    QVERIFY(vast::BrightnessManager::clampPercent(-1) >= 0);
}

void TestBrightnessDisplay::clampPercentClampsAboveRange() {
    QCOMPARE(vast::BrightnessManager::clampPercent(101), 100);
    QCOMPARE(vast::BrightnessManager::clampPercent(1000), 100);
}

void TestBrightnessDisplay::clampPercentPassesThroughInRange() {
    QCOMPARE(vast::BrightnessManager::clampPercent(0), 0);
    QCOMPARE(vast::BrightnessManager::clampPercent(50), 50);
    QCOMPARE(vast::BrightnessManager::clampPercent(100), 100);
}

void TestBrightnessDisplay::backlightRoundTripsPercent() {
    const auto root = freshRoot("roundtrip");
    writeMaxBrightness(root, 1000);

    // The write scales percent * max / 100 and the read scales current * 100 /
    // max. Only a round trip proves the two scalings agree.
    for (const int percent : {0, 25, 50, 75, 100}) {
        const auto written = vast::BrightnessManager::writeBacklightBrightness(root, percent);
        QVERIFY2(written.has_value(), written.error().message.c_str());

        const auto read = vast::BrightnessManager::readBacklightBrightness(root);
        QVERIFY2(read.has_value(), read.error().message.c_str());
        QCOMPARE(*read, percent);
    }
}

void TestBrightnessDisplay::readBacklightScalesAgainstMaxBrightness() {
    const auto root = freshRoot("scaling");
    writeMaxBrightness(root, 255);
    writeRawBrightness(root, 51);

    const auto read = vast::BrightnessManager::readBacklightBrightness(root);
    QVERIFY(read.has_value());
    QCOMPARE(*read, 20);

    const auto root2 = freshRoot("scaling2");
    writeMaxBrightness(root2, 1000);
    writeRawBrightness(root2, 500);

    const auto read2 = vast::BrightnessManager::readBacklightBrightness(root2);
    QVERIFY(read2.has_value());
    QCOMPARE(*read2, 50);
}

void TestBrightnessDisplay::writeBacklightScalesByTheDeviceMaxNotOneHundred() {
    const auto root = freshRoot("scaledwrite");
    writeMaxBrightness(root, 255);

    const auto written = vast::BrightnessManager::writeBacklightBrightness(root, 50);
    QVERIFY(written.has_value());

    // 50 * 255 / 100 = 127, not the literal 50.
    QCOMPARE(readRawBrightness(root), QStringLiteral("127"));
}

void TestBrightnessDisplay::readBacklightFailsOnAMissingDirectory() {
    const std::filesystem::path missing = mDir->path().toStdString() + "/definitely-not-here";

    const auto                  read = vast::BrightnessManager::readBacklightBrightness(missing);

    QVERIFY(!read.has_value());
    QVERIFY(read.error().message.find(missing.string()) != std::string::npos);
}

void TestBrightnessDisplay::readBacklightFailsWhenMaxBrightnessIsZero() {
    const auto root = freshRoot("zeromax");
    writeMaxBrightness(root, 0);
    writeRawBrightness(root, 5);

    const auto read = vast::BrightnessManager::readBacklightBrightness(root);

    QVERIFY(!read.has_value());
    QCOMPARE(read.error().message, std::string("max_brightness is 0"));
}

void TestBrightnessDisplay::readBacklightFailsWhenTheDirectoryHasNoFiles() {
    const auto root = freshRoot("empty");

    const auto read = vast::BrightnessManager::readBacklightBrightness(root);

    QVERIFY(!read.has_value());
    QVERIFY(!read.error().message.empty());
}

void TestBrightnessDisplay::writeBacklightFailsOnAMissingDirectory() {
    const std::filesystem::path missing = mDir->path().toStdString() + "/definitely-not-here";

    const auto                  written = vast::BrightnessManager::writeBacklightBrightness(missing, 50);

    QVERIFY(!written.has_value());
    // The message names the brightness file, not max_brightness: the branch is
    // taken because max_brightness could not be read, but the operator-facing
    // hint is about the file the user is expected to be able to write.
    QVERIFY(written.error().message.find("cannot write") != std::string::npos);
    QVERIFY(written.error().message.find("brightness") != std::string::npos);
}

void TestBrightnessDisplay::writeBacklightFailsWhenBrightnessIsNotWritable() {
    if (mRoot)
        QSKIP("running as root: permission bits do not prevent writing");

    const auto root = freshRoot("readonly");
    writeMaxBrightness(root, 255);
    writeRawBrightness(root, 100);
    QVERIFY(QFile::setPermissions(QString::fromStdString((root / "brightness").string()), QFile::ReadOwner));

    const auto written = vast::BrightnessManager::writeBacklightBrightness(root, 50);

    QVERIFY(!written.has_value());
    QVERIFY(written.error().message.find("cannot write brightness") != std::string::npos);
}

QTEST_GUILESS_MAIN(TestBrightnessDisplay)
#include "tst_brightnessdisplay.moc"
