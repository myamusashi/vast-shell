#include "WallpaperFixtures.hpp"

#include <qcolor.h>
#include <qcoreapplication.h>
#include <qelapsedtimer.h>
#include <qeventloop.h>
#include <qfileinfo.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>
#include <qurl.h>
#include <qvariant.h>

#include "../../Utils/ColorMaterial.hpp"

// Rebuilds are debounced and finish on a worker thread, so waits pump the
// event loop. The ceiling stops a deadlock from hanging the run.
namespace {

    constexpr int K_TIMEOUT_MS = 30000;
    constexpr int K_DRAIN_MS   = 2000;

    template <typename Predicate>
    bool spinUntil(Predicate predicate) {
        QElapsedTimer timer;
        timer.start();
        while (!predicate() && timer.elapsed() < K_TIMEOUT_MS)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        return predicate();
    }

    // Waits on the signal, not on `ready`: `ready` still holds the previous
    // result while the next rebuild is in flight.
    bool waitForColorsChanged(ColorMaterial& material, const QVariantMap& before) {
        QSignalSpy    spy(&material, &ColorMaterial::colorsChanged);
        QElapsedTimer timer;
        timer.start();
        while (spy.isEmpty() && timer.elapsed() < K_TIMEOUT_MS)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        return !spy.isEmpty() && material.colors() != before;
    }

    // Fixed budget, for cases where no signal is guaranteed.
    void drain(int budgetMs) {
        QElapsedTimer timer;
        timer.start();
        while (timer.elapsed() < budgetMs)
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
    }

} // namespace

class TestColorMaterial : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void startsIdleAndUnready();
    void clearsStateForEmptySource();
    void clearsStateForNonLocalSource();
    void reportsErrorForMissingFile();
    void errorClearsWhenSourceBecomesValid();
    void buildsPaletteForEveryFixture_data();
    void buildsPaletteForEveryFixture();
    void acceptsPlainAbsolutePathWithoutScheme();
    void repeatedSourceChangeEmitsOnce();
    void settingUnchangedPropertyDoesNotNotify();
    void inFlightResultCannotResurrectClearedState();
    void darkModeToggleChangesColors();
    void schemeChangeChangesColors();
    void rescaleSizeChangeKeepsPaletteValid();
    void contrastLevelChangeKeepsPaletteValid();
    void smartToggleKeepsPaletteValid();

  private:
    QStringList mImages;
};

void TestColorMaterial::initTestCase() {
    QString error;
    QVERIFY2(vast::test::requireWallpaperFixtures(error), qPrintable(error));
    mImages = vast::test::wallpaperFixtures();
    QCOMPARE(mImages.size(), 20);
}

void TestColorMaterial::startsIdleAndUnready() {
    ColorMaterial material;

    QCOMPARE(material.source(), QUrl());
    QCOMPARE(material.rescaleSize(), 128);
    QCOMPARE(material.darkMode(), true);
    QCOMPARE(material.scheme(), ColorMaterial::TonalSpot);
    QCOMPARE(material.contrastLevel(), 0.0);
    QCOMPARE(material.smart(), false);
    QVERIFY(!material.ready());
    QVERIFY(material.error().isEmpty());
    QVERIFY(material.colors().isEmpty());
}

// An unset source yields an empty palette and no error.
void TestColorMaterial::clearsStateForEmptySource() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));
    QVERIFY(!material.colors().isEmpty());

    material.setSource(QUrl());
    QVERIFY(waitForColorsChanged(material, material.colors()));
    QVERIFY(material.colors().isEmpty());
    QVERIFY(material.error().isEmpty());
}

// A non-local source takes the empty-path branch: the palette clears and
// nothing ever becomes ready, so wait on a fixed budget.
void TestColorMaterial::clearsStateForNonLocalSource() {
    ColorMaterial material;
    material.setSource(QUrl(QStringLiteral("https://example.invalid/wallpaper.png")));

    drain(K_DRAIN_MS);
    QVERIFY(material.colors().isEmpty());
    QVERIFY(material.error().isEmpty());
    QVERIFY(!material.ready());
}

void TestColorMaterial::reportsErrorForMissingFile() {
    ColorMaterial material;
    QSignalSpy    spy(&material, &ColorMaterial::errorChanged);

    material.setSource(QUrl::fromLocalFile(QStringLiteral("/nonexistent/vast-colormaterial-fixture.jpg")));
    QVERIFY(spinUntil([&material] { return !material.error().isEmpty(); }));
    QVERIFY(!material.ready());
    QVERIFY(material.colors().isEmpty());
    QCOMPARE(spy.count(), 1);
}

// A later good source must clear a stale error.
void TestColorMaterial::errorClearsWhenSourceBecomesValid() {
    ColorMaterial material;

    material.setSource(QUrl::fromLocalFile(QStringLiteral("/nonexistent/vast-colormaterial-fixture.jpg")));
    QVERIFY(spinUntil([&material] { return !material.error().isEmpty(); }));

    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready() && material.error().isEmpty(); }));
    QVERIFY(!material.colors().isEmpty());
}

void TestColorMaterial::buildsPaletteForEveryFixture_data() {
    QTest::addColumn<QString>("image");
    for (const QString& image : vast::test::wallpaperFixtures())
        QTest::newRow(qPrintable(QFileInfo(image).fileName().toUtf8().constData())) << image;
}

void TestColorMaterial::buildsPaletteForEveryFixture() {
    QFETCH(QString, image);

    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(image));
    QVERIFY2(spinUntil([&material] { return material.ready(); }), qPrintable(material.error()));

    const QVariantMap colors = material.colors();
    for (const QString& role : {QStringLiteral("primary"), QStringLiteral("onPrimary"), QStringLiteral("surface"), QStringLiteral("onSurface"), QStringLiteral("background"),
                                QStringLiteral("error"), QStringLiteral("surfaceContainer"), QStringLiteral("outline"), QStringLiteral("secondary"), QStringLiteral("tertiary")})
        QVERIFY2(colors.contains(role), qPrintable(QStringLiteral("missing %1").arg(role)));

    for (auto it = colors.constBegin(); it != colors.constEnd(); ++it) {
        const QString value = it.value().toString();
        QVERIFY2(value.size() == 7 && value.startsWith(QLatin1Char('#')), qPrintable(QStringLiteral("%1 = %2").arg(it.key(), value)));
    }

    // QML reads sourceColor for previews and the map for bindings; they must
    // agree.
    QCOMPARE(material.sourceColor().name(QColor::HexRgb).toUpper(), colors.value(QStringLiteral("sourceColor")));
    QVERIFY(material.sourceColor().isValid());
}

// MPRIS art paths arrive as scheme-less absolute paths.
void TestColorMaterial::acceptsPlainAbsolutePathWithoutScheme() {
    ColorMaterial material;
    const QUrl    bare(mImages.first());
    QVERIFY(bare.scheme().isEmpty());

    material.setSource(bare);
    QVERIFY2(spinUntil([&material] { return material.ready(); }), qPrintable(material.error()));
    QVERIFY(!material.colors().isEmpty());
}

// A burst of changes must coalesce into one rebuild.
void TestColorMaterial::repeatedSourceChangeEmitsOnce() {
    ColorMaterial material;
    QSignalSpy    colorsSpy(&material, &ColorMaterial::colorsChanged);

    for (const QString& image : mImages)
        material.setSource(QUrl::fromLocalFile(image));

    QVERIFY(spinUntil([&material] { return material.ready(); }));
    QCOMPARE(colorsSpy.count(), 1);
    QCOMPARE(material.source().toLocalFile(), mImages.last());
}

void TestColorMaterial::settingUnchangedPropertyDoesNotNotify() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));

    QSignalSpy sourceSpy(&material, &ColorMaterial::sourceChanged);
    QSignalSpy darkSpy(&material, &ColorMaterial::darkModeChanged);
    QSignalSpy colorsSpy(&material, &ColorMaterial::colorsChanged);

    material.setSource(QUrl::fromLocalFile(mImages.first()));
    material.setDarkMode(material.darkMode());
    QCoreApplication::processEvents(QEventLoop::AllEvents, 50);

    QCOMPARE(sourceSpy.count(), 0);
    QCOMPARE(darkSpy.count(), 0);
    QCOMPARE(colorsSpy.count(), 0);
}

// The generation counter must stop an already-queued job from repopulating the
// palette after the source was cleared.
void TestColorMaterial::inFlightResultCannotResurrectClearedState() {
    ColorMaterial material;

    material.setSource(QUrl::fromLocalFile(mImages.first()));
    // Pump just enough to queue the job on the worker.
    QCoreApplication::processEvents(QEventLoop::AllEvents, 20);

    material.setSource(QUrl());
    QVERIFY(spinUntil([&material] { return material.colors().isEmpty(); }));
    QVERIFY(!material.ready());

    // Give any queued job ample time to land; it must be discarded.
    drain(K_DRAIN_MS);
    QVERIFY2(material.colors().isEmpty(), "a superseded result repopulated the palette after the source was cleared");
    QVERIFY(material.error().isEmpty());
}

void TestColorMaterial::darkModeToggleChangesColors() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));
    const QVariantMap darkColors = material.colors();

    material.setDarkMode(false);
    QVERIFY2(waitForColorsChanged(material, darkColors), "darkMode toggle produced an identical palette");
    QVERIFY(material.error().isEmpty());
}

void TestColorMaterial::schemeChangeChangesColors() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));
    const QVariantMap tonalSpot = material.colors();

    material.setScheme(ColorMaterial::Fidelity);
    QVERIFY2(waitForColorsChanged(material, tonalSpot), "fidelity scheme produced the tonal-spot palette");
    QVERIFY(material.error().isEmpty());
}

// rescaleSize and smart can quantize to the same source color as the defaults,
// and applyResult() only emits on a real change, so these wait on a drain.
void TestColorMaterial::rescaleSizeChangeKeepsPaletteValid() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));

    material.setRescaleSize(64);
    drain(K_DRAIN_MS);
    QVERIFY(material.ready());
    QVERIFY(!material.colors().isEmpty());
    QVERIFY(material.error().isEmpty());
    QVERIFY(material.colors().contains(QStringLiteral("primary")));
}

void TestColorMaterial::contrastLevelChangeKeepsPaletteValid() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));
    const QVariantMap normal = material.colors();

    material.setContrastLevel(1.0);
    QVERIFY2(waitForColorsChanged(material, normal), "contrastLevel 1.0 produced the default palette");
    QVERIFY(material.error().isEmpty());
}

void TestColorMaterial::smartToggleKeepsPaletteValid() {
    ColorMaterial material;
    material.setSource(QUrl::fromLocalFile(mImages.first()));
    QVERIFY(spinUntil([&material] { return material.ready(); }));

    material.setSmart(true);
    drain(K_DRAIN_MS);
    QVERIFY(material.ready());
    QVERIFY(material.error().isEmpty());
    QVERIFY(material.colors().contains(QStringLiteral("primary")));
}

QTEST_MAIN(TestColorMaterial)
#include "tst_colormaterial.moc"
