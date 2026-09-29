#include "WallpaperFixtures.hpp"

#include <qfileinfo.h>
#include <qlist.h>
#include <qmap.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtemporaryfile.h>
#include <qtest.h>

#include "MaterialPalette.hpp"
#include "PaletteBuilder.hpp"
#include "PaletteValidation.hpp"

#include "cpp/cam/hct.h"
#include "cpp/utils/utils.h"

#include <cmath>

using material_color_utilities::Argb;
using material_color_utilities::Hct;

namespace {

    // The five fg/bg pairs the shell paints on top of each other. Restated
    // here so a weakened threshold in validatePalette() is caught.
    const QList<QPair<QString, QString>>& contrastPairs() {
        static const QList<QPair<QString, QString>> pairs{
            {QStringLiteral("onSurface"), QStringLiteral("surface")},
            {QStringLiteral("onPrimary"), QStringLiteral("primary")},
            {QStringLiteral("onError"), QStringLiteral("error")},
            {QStringLiteral("onSurfaceVariant"), QStringLiteral("surfaceVariant")},
            {QStringLiteral("onPrimaryContainer"), QStringLiteral("primaryContainer")},
        };
        return pairs;
    }

    const QList<QString>& allSchemes() {
        static const QList<QString> schemes{
            QStringLiteral("tonal-spot"), QStringLiteral("vibrant"),  QStringLiteral("expressive"), QStringLiteral("fruit-salad"), QStringLiteral("monochrome"),
            QStringLiteral("rainbow"),    QStringLiteral("fidelity"), QStringLiteral("content"),    QStringLiteral("neutral"),
        };
        return schemes;
    }

    double toneOf(const QMap<QString, QString>& colors, const QString& role) {
        const QString hex = colors.value(role);
        return Hct(0xFF000000u | static_cast<Argb>(hex.mid(1).toUInt(nullptr, 16))).get_tone();
    }

    bool isHexColor(const QString& value) {
        if (value.size() != 7 || !value.startsWith(QLatin1Char('#')))
            return false;
        bool       ok   = false;
        const auto rest = value.mid(1);
        rest.toUInt(&ok, 16);
        return ok;
    }

    // Container ramp, lowest elevation first. Tone must move monotonically or
    // elevation cues invert; the direction flips with mode (dark 0->18,
    // light 100->90).
    const QList<QString>& surfaceRamp() {
        static const QList<QString> ramp{
            QStringLiteral("surfaceContainerLowest"), QStringLiteral("surfaceContainerLow"),     QStringLiteral("surfaceContainer"),
            QStringLiteral("surfaceContainerHigh"),   QStringLiteral("surfaceContainerHighest"),
        };
        return ramp;
    }

} // namespace

class TestPalette : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void everyFixtureHasDistinctSourceColor();
    void sourceColorIsStableAcrossRepeatedExtraction();
    void producesEveryRequiredRole_data();
    void producesEveryRequiredRole();
    void allRolesAreHexColors_data();
    void allRolesAreHexColors();
    void noSurfaceRoleIsPureBlackOrWhite_data();
    void noSurfaceRoleIsPureBlackOrWhite();
    void contrastPairsClearTheToneGap_data();
    void contrastPairsClearTheToneGap();
    void lightModeIsLighterThanDarkMode();
    void surfaceRampIsMonotonic_data();
    void surfaceRampIsMonotonic();
    void survivesEveryScheme_data();
    void survivesEveryScheme();
    void smartFallsBackToNeutralForGreyInput();
    void contrastLevelChangesThePalette();
    void rescaleSizeDoesNotChangeValidity_data();
    void rescaleSizeDoesNotChangeValidity();
    void reportsErrorForMissingFile();
    void reportsErrorForUnreadableImage();
    void buildFromColorMatchesBuildFromImageForSameSource();
    void acceptsHexWithOrWithoutHash();
    void rejectsMalformedHexInput_data();
    void rejectsMalformedHexInput();

  private:
    QStringList mImages;
};

// 20 images x 2 modes covers every fixture in every pairing.
void TestPalette::initTestCase() {
    QString error;
    QVERIFY2(vast::test::requireWallpaperFixtures(error), qPrintable(error));
    mImages = vast::test::wallpaperFixtures();
    QCOMPARE(mImages.size(), 20);
}

void TestPalette::producesEveryRequiredRole_data() {
    QTest::addColumn<QString>("image");
    QTest::addColumn<QString>("mode");
    for (const QString& image : vast::test::wallpaperFixtures()) {
        for (const QString& mode : {QStringLiteral("dark"), QStringLiteral("light")}) {
            const QString row = QStringLiteral("%1-%2").arg(QFileInfo(image).fileName(), mode);
            QTest::newRow(qPrintable(row)) << image << mode;
        }
    }
}

void TestPalette::producesEveryRequiredRole() {
    QFETCH(QString, image);
    QFETCH(QString, mode);

    const SMaterialPaletteResult result = buildPalette(image, mode, QStringLiteral("tonal-spot"), false);
    QVERIFY2(result.error.isEmpty(), qPrintable(result.error));

    for (const QString& role : requiredRoles())
        QVERIFY2(result.colors.contains(role), qPrintable(QStringLiteral("missing role %1").arg(role)));

    // Read by QML but outside requiredRoles(), so check them separately.
    for (const QString& role : {QStringLiteral("success"), QStringLiteral("onSuccess"), QStringLiteral("successContainer"), QStringLiteral("onSuccessContainer"),
                                QStringLiteral("sourceColor"), QStringLiteral("neutralPaletteKeyColor")})
        QVERIFY2(result.colors.contains(role), qPrintable(QStringLiteral("missing role %1").arg(role)));
}

void TestPalette::allRolesAreHexColors_data() {
    producesEveryRequiredRole_data();
}

void TestPalette::allRolesAreHexColors() {
    QFETCH(QString, image);
    QFETCH(QString, mode);

    const SMaterialPaletteResult result = buildPalette(image, mode, QStringLiteral("tonal-spot"), false);
    for (auto it = result.colors.constBegin(); it != result.colors.constEnd(); ++it)
        QVERIFY2(isHexColor(it.value()), qPrintable(QStringLiteral("%1 = %2").arg(it.key(), it.value())));
}

void TestPalette::noSurfaceRoleIsPureBlackOrWhite_data() {
    producesEveryRequiredRole_data();
}

void TestPalette::noSurfaceRoleIsPureBlackOrWhite() {
    QFETCH(QString, image);
    QFETCH(QString, mode);

    const SMaterialPaletteResult result = buildPalette(image, mode, QStringLiteral("tonal-spot"), false);
    for (const QString& role : requiredRoles()) {
        if (!role.contains(QStringLiteral("surface"), Qt::CaseInsensitive))
            continue;
        const QString value = result.colors.value(role).toUpper();
        QVERIFY2(value != QLatin1String("#000000") && value != QLatin1String("#FFFFFF"), qPrintable(QStringLiteral("%1 is pure %2 for %3").arg(role, value, mode)));
    }
}

void TestPalette::contrastPairsClearTheToneGap_data() {
    producesEveryRequiredRole_data();
}

void TestPalette::contrastPairsClearTheToneGap() {
    QFETCH(QString, image);
    QFETCH(QString, mode);

    const SMaterialPaletteResult result = buildPalette(image, mode, QStringLiteral("tonal-spot"), false);
    for (const auto& [fg, bg] : contrastPairs()) {
        const double gap = std::abs(toneOf(result.colors, fg) - toneOf(result.colors, bg));
        QVERIFY2(gap >= 40.0, qPrintable(QStringLiteral("%1/%2 tone gap %3 for %4").arg(fg, bg).arg(gap).arg(mode)));
    }
}

void TestPalette::surfaceRampIsMonotonic_data() {
    producesEveryRequiredRole_data();
}

void TestPalette::surfaceRampIsMonotonic() {
    QFETCH(QString, image);
    QFETCH(QString, mode);

    const bool dark     = mode == QLatin1String("dark");
    const auto result   = buildPalette(image, mode, QStringLiteral("tonal-spot"), false);
    double     previous = toneOf(result.colors, surfaceRamp().first());
    for (const QString& role : surfaceRamp()) {
        const double current = toneOf(result.colors, role);
        const bool   ordered = dark ? current >= previous : current <= previous;
        QVERIFY2(ordered, qPrintable(QStringLiteral("%1 tone %2 breaks the %3 ramp after %4").arg(role).arg(current).arg(mode).arg(previous)));
        previous = current;
    }
}

void TestPalette::lightModeIsLighterThanDarkMode() {
    for (const QString& image : mImages) {
        const SMaterialPaletteResult dark  = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
        const SMaterialPaletteResult light = buildPalette(image, QStringLiteral("light"), QStringLiteral("tonal-spot"), false);
        QVERIFY2(toneOf(light.colors, QStringLiteral("surface")) > toneOf(dark.colors, QStringLiteral("surface")),
                 qPrintable(QStringLiteral("surface not lighter in light mode for %1").arg(image)));
        QVERIFY2(toneOf(light.colors, QStringLiteral("onSurface")) < toneOf(dark.colors, QStringLiteral("onSurface")),
                 qPrintable(QStringLiteral("onSurface not darker in light mode for %1").arg(image)));
    }
}

// Different wallpapers must produce different palettes.
void TestPalette::everyFixtureHasDistinctSourceColor() {
    QMap<QString, QString> sourceByHueBucket;
    for (const QString& image : mImages) {
        const SMaterialPaletteResult result = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
        QVERIFY2(result.error.isEmpty(), qPrintable(result.error));
        const QString hex = result.colors.value(QStringLiteral("sourceColor"));
        QVERIFY2(isHexColor(hex), qPrintable(QStringLiteral("bad sourceColor %1").arg(hex)));

        const double hue = Hct(0xFF000000u | static_cast<Argb>(hex.mid(1).toUInt(nullptr, 16))).get_hue();
        sourceByHueBucket.insert(QString::number(qRound(hue / 15.0)), hex);
    }
    // A quantizer stuck on one color would collapse to one or two buckets.
    QVERIFY2(sourceByHueBucket.size() >= 12,
             qPrintable(QStringLiteral("only %1 distinct 15-deg hue buckets across %2 wallpapers").arg(sourceByHueBucket.size()).arg(mImages.size())));
}

void TestPalette::sourceColorIsStableAcrossRepeatedExtraction() {
    for (const QString& image : mImages) {
        const QString first  = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false).colors.value(QStringLiteral("sourceColor"));
        const QString second = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false).colors.value(QStringLiteral("sourceColor"));
        QCOMPARE(second, first);
    }
}

void TestPalette::survivesEveryScheme_data() {
    QTest::addColumn<QString>("image");
    for (const QString& image : mImages)
        QTest::newRow(qPrintable(QFileInfo(image).fileName().toUtf8().constData())) << image;
}

void TestPalette::survivesEveryScheme() {
    QFETCH(QString, image);

    for (const QString& scheme : allSchemes()) {
        for (const QString& mode : {QStringLiteral("dark"), QStringLiteral("light")}) {
            const SMaterialPaletteResult result = buildPalette(image, mode, scheme, false);
            QVERIFY2(result.error.isEmpty(), qPrintable(QStringLiteral("%1/%2: %3").arg(scheme, mode, result.error)));
            for (const QString& role : requiredRoles())
                QVERIFY2(result.colors.contains(role), qPrintable(QStringLiteral("%1/%2 missing %3").arg(scheme, mode, role)));
        }
    }
}

void TestPalette::smartFallsBackToNeutralForGreyInput() {
    // smart=true falls back to neutral below chroma 20; grey guarantees it.
    const QString                greyHex = QStringLiteral("#808080");
    const SMaterialPaletteResult smart   = buildPaletteFromColor(greyHex, QStringLiteral("dark"), QStringLiteral("vibrant"), true);
    const SMaterialPaletteResult neutral = buildPaletteFromColor(greyHex, QStringLiteral("dark"), QStringLiteral("neutral"), true);
    const SMaterialPaletteResult vibrant = buildPaletteFromColor(greyHex, QStringLiteral("dark"), QStringLiteral("vibrant"), false);

    QVERIFY2(smart.error.isEmpty(), qPrintable(smart.error));
    QCOMPARE(smart.colors, neutral.colors);
    QVERIFY2(smart.colors != vibrant.colors, "smart grey fallback produced the same palette as plain vibrant");
}

void TestPalette::contrastLevelChangesThePalette() {
    const QString                image = mImages.first();

    const SMaterialPaletteResult normal = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false, 128, 0.0);
    const SMaterialPaletteResult high   = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false, 128, 1.0);
    const SMaterialPaletteResult low    = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false, 128, -1.0);

    QVERIFY2(normal.error.isEmpty() && high.error.isEmpty() && low.error.isEmpty(), "contrast variant failed validation");
    QVERIFY2(high.colors != low.colors, "contrastLevel -1 and 1 produced identical palettes");
}

void TestPalette::rescaleSizeDoesNotChangeValidity_data() {
    QTest::addColumn<int>("rescaleSize");
    for (const int size : {32, 64, 128, 256})
        QTest::newRow(qPrintable(QString::number(size).toUtf8().constData())) << size;
}

void TestPalette::rescaleSizeDoesNotChangeValidity() {
    QFETCH(int, rescaleSize);

    for (const QString& image : mImages) {
        const SMaterialPaletteResult result = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false, rescaleSize);
        QVERIFY2(result.error.isEmpty(), qPrintable(QStringLiteral("%1 at %2px: %3").arg(image).arg(rescaleSize).arg(result.error)));
        QVERIFY2(result.colors.value(QStringLiteral("sourceColor")) != QStringLiteral("#000000"), "quantizer fell back to black");
    }
}

void TestPalette::reportsErrorForMissingFile() {
    const SMaterialPaletteResult result = buildPalette(QStringLiteral("/nonexistent/vast-wallpaper-fixture.jpg"), QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
    QVERIFY(!result.error.isEmpty());
    QVERIFY(result.colors.isEmpty());
}

void TestPalette::reportsErrorForUnreadableImage() {
    QTemporaryFile junk;
    QVERIFY(junk.open());
    junk.write("this is not a png");
    junk.flush();

    const SMaterialPaletteResult result = buildPalette(junk.fileName(), QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
    QVERIFY(!result.error.isEmpty());
    QVERIFY(result.colors.isEmpty());
}

// Image and color paths must agree for the same source color.
void TestPalette::buildFromColorMatchesBuildFromImageForSameSource() {
    for (const QString& image : mImages) {
        const SMaterialPaletteResult fromImage = buildPalette(image, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
        const SMaterialPaletteResult fromColor =
            buildPaletteFromColor(fromImage.colors.value(QStringLiteral("sourceColor")), QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
        QCOMPARE(fromColor.colors, fromImage.colors);
    }
}

void TestPalette::rejectsMalformedHexInput_data() {
    QTest::addColumn<QString>("hex");
    QTest::newRow("empty") << QString();
    QTest::newRow("three-digit") << QStringLiteral("#FFF");
    QTest::newRow("too-long") << QStringLiteral("#4287F5AA");
    QTest::newRow("non-hex") << QStringLiteral("#GGGGGG");
    QTest::newRow("alpha-prefixed") << QStringLiteral("#FF4287F5");
    QTest::newRow("named-color") << QStringLiteral("rebeccapurple");
    QTest::newRow("hash-only") << QStringLiteral("#");
}

// parseColorHex strips an optional '#', so bare RRGGBB is valid input.
void TestPalette::acceptsHexWithOrWithoutHash() {
    const SMaterialPaletteResult withHash    = buildPaletteFromColor(QStringLiteral("#4287F5"), QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
    const SMaterialPaletteResult withoutHash = buildPaletteFromColor(QStringLiteral("4287F5"), QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);

    QVERIFY2(withHash.error.isEmpty(), qPrintable(withHash.error));
    QCOMPARE(withoutHash.colors, withHash.colors);
    QCOMPARE(withoutHash.sourceColor, withHash.sourceColor);
}

void TestPalette::rejectsMalformedHexInput() {
    QFETCH(QString, hex);

    const SMaterialPaletteResult result = buildPaletteFromColor(hex, QStringLiteral("dark"), QStringLiteral("tonal-spot"), false);
    QVERIFY(!result.error.isEmpty());
    QVERIFY(result.colors.isEmpty());
}

QTEST_MAIN(TestPalette)
#include "tst_palette.moc"
