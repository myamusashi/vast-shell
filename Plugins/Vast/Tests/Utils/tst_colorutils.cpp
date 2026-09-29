#include <qcolor.h>
#include <cmath>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include "../../Utils/ColorUtils.hpp"

namespace {

    // Two roles: one shared key and one second key.
    [[nodiscard]] QVariantMap twoColorPalette(const QString& key, const QString& fromHex, const QString& toHex) {
        QVariantMap m;
        m.insert(key, fromHex);
        m.insert(key + QStringLiteral("2"), toHex);
        return m;
    }

    // QRgb, not int: 0xFFFF0000 exceeds INT_MAX.
    constexpr QRgb kRedRgba   = 0xFFFF0000; // #FF0000
    constexpr QRgb kBlueRgba  = 0xFF0000FF; // #0000FF
    constexpr QRgb kHalfRgba  = 0xFF8C53A2; // #8C53A2, the OKLab midpoint
    constexpr QRgb kHalfARgba = 0x808C53A2; // the same RGB, alpha 128

} // namespace

class TestColorUtils : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void blendAtZeroReturnsSourceVerbatim();
    void blendAtOneReturnsDestinationVerbatim();
    void blendClampsTBelowZero();
    void blendClampsTAboveOne();
    void blendAtHalfIsPerceptualNotLinear();
    void blendInterpolatesAlphaIndependently();

    void fromStringParsesSixDigitHex();
    void fromStringParsesEightDigitHexWithAlpha();
    void fromStringAcceptsShorthandThroughQColor();
    void fromStringAcceptsNamedColours();
    void fromStringRejectsGarbage();
    void fromStringRejectsEmptyInput();

    void blendPalettesKeepsOnlyDestinationKeys();
    void blendPalettesUsesDestinationWhenSourceLacksTheKey();
    void blendPalettesAtZeroReproducesTheSource();
    void blendPalettesAtOneReproducesTheDestination();
    void blendPalettesAcceptsQColorAndStringValues();

    void hctRoundTripIsExact();
    void rgbToHctReturnsExactlyThreeKeys();
    void createAnalogousColorWithZeroShiftIsIdentity();
    void createAnalogousColorWithFullTurnIsIdentity();
    void createAnalogousColorWrapsNegativeShifts();
    void createTonalColorIsDarkerForLowTone();
    void createTonalColorNearBaseToneKeepsChroma();
    void createTonalColorStaysInGamutForExtremeTone();
};

void TestColorUtils::blendAtZeroReturnsSourceVerbatim() {
    // t <= 0 returns src before the OKLab round trip, so it is bit-identical.
    QCOMPARE(ColorUtils::blendColors(QColor::fromRgba(kRedRgba), QColor::fromRgba(kBlueRgba), 0.0).rgba(), kRedRgba);
}

void TestColorUtils::blendAtOneReturnsDestinationVerbatim() {
    QCOMPARE(ColorUtils::blendColors(QColor::fromRgba(kRedRgba), QColor::fromRgba(kBlueRgba), 1.0).rgba(), kBlueRgba);
}

void TestColorUtils::blendClampsTBelowZero() {
    // Negative t clamps to 0 and returns src.
    QCOMPARE(ColorUtils::blendColors(QColor::fromRgba(kRedRgba), QColor::fromRgba(kBlueRgba), -5.0).rgba(), kRedRgba);
}

void TestColorUtils::blendClampsTAboveOne() {
    QCOMPARE(ColorUtils::blendColors(QColor::fromRgba(kRedRgba), QColor::fromRgba(kBlueRgba), 5.0).rgba(), kBlueRgba);
}

void TestColorUtils::blendAtHalfIsPerceptualNotLinear() {
    // Perceptual midpoint, not the naive per-channel #800080.
    const QColor mid = ColorUtils::blendColors(QColor::fromRgba(kRedRgba), QColor::fromRgba(kBlueRgba), 0.5);

    QCOMPARE(mid.rgba(), kHalfRgba);
    QVERIFY2(mid != QColor(0x800080), "blend degraded to a naive per-channel average");
}

void TestColorUtils::blendInterpolatesAlphaIndependently() {
    // Same RGB as the opaque midpoint, with alpha the midpoint of 64 and 192.
    const QColor mid = ColorUtils::blendColors(QColor(255, 0, 0, 64), QColor(0, 0, 255, 192), 0.5);

    QCOMPARE(mid.rgba(), kHalfARgba);
    QCOMPARE(mid.alpha(), 128);
}

void TestColorUtils::fromStringParsesSixDigitHex() {
    QCOMPARE(ColorUtils::fromString(QStringLiteral("#123456")).rgba(), 0xFF123456);
}

void TestColorUtils::fromStringParsesEightDigitHexWithAlpha() {
    // 8-digit hex is #RRGGBBAA: the trailing pair is alpha.
    const QColor c = ColorUtils::fromString(QStringLiteral("#12345678"));
    QCOMPARE(c.rgba(), 0x12345678);
    QCOMPARE(c.alpha(), 0x12);
    QCOMPARE(c.red(), 0x34);
    QCOMPARE(c.blue(), 0x78);
}

void TestColorUtils::fromStringAcceptsShorthandThroughQColor() {
    // Shorthand misses the 6/8 fast path and goes through QColor(value).
    QCOMPARE(ColorUtils::fromString(QStringLiteral("#abc")).rgba(), 0xFFAABBCC);
}

void TestColorUtils::fromStringAcceptsNamedColours() {
    QCOMPARE(ColorUtils::fromString(QStringLiteral("red")).rgba(), kRedRgba);
}

void TestColorUtils::fromStringRejectsGarbage() {
    // Check isValid: an invalid QColor still reports #000000 from name().
    QVERIFY(!ColorUtils::fromString(QStringLiteral("notacolour")).isValid());
}

void TestColorUtils::fromStringRejectsEmptyInput() {
    QVERIFY(!ColorUtils::fromString(QString()).isValid());
}

void TestColorUtils::blendPalettesKeepsOnlyDestinationKeys() {
    QVariantMap from;
    from.insert(QStringLiteral("a"), QStringLiteral("#FF0000"));
    from.insert(QStringLiteral("onlyInFrom"), QStringLiteral("#00FF00"));

    QVariantMap to;
    to.insert(QStringLiteral("a"), QStringLiteral("#0000FF"));
    to.insert(QStringLiteral("onlyInTo"), QStringLiteral("#FFFF00"));

    const QVariantMap out = ColorUtils::blendPalettes(from, to, 0.5);

    // Iterating `to` drops any key present only in `from`.
    QCOMPARE(out.size(), 2);
    QVERIFY(out.contains(QStringLiteral("a")));
    QVERIFY(out.contains(QStringLiteral("onlyInTo")));
    QVERIFY(!out.contains(QStringLiteral("onlyInFrom")));
}

void TestColorUtils::blendPalettesUsesDestinationWhenSourceLacksTheKey() {
    QVariantMap from;
    QVariantMap to;
    to.insert(QStringLiteral("new"), QStringLiteral("#0000FF"));

    // src falls back to dst, so the key is the destination at every t.
    for (const qreal t : {0.0, 0.5, 1.0}) {
        const QVariantMap out = ColorUtils::blendPalettes(from, to, t);
        QCOMPARE(out.value(QStringLiteral("new")).value<QColor>().rgba(), kBlueRgba);
    }
}

void TestColorUtils::blendPalettesAtZeroReproducesTheSource() {
    // from and to must actually differ, or the blend is a no-op.
    const QVariantMap from = twoColorPalette(QStringLiteral("primary"), QStringLiteral("#FF0000"), QStringLiteral("#00FF00"));
    const QVariantMap to   = twoColorPalette(QStringLiteral("primary"), QStringLiteral("#0000FF"), QStringLiteral("#FFFF00"));

    const QVariantMap out = ColorUtils::blendPalettes(from, to, 0.0);

    QCOMPARE(out.value(QStringLiteral("primary")).value<QColor>().rgba(), kRedRgba);
    QCOMPARE(out.value(QStringLiteral("primary2")).value<QColor>().rgba(), 0xFF00FF00);
}

void TestColorUtils::blendPalettesAtOneReproducesTheDestination() {
    const QVariantMap from = twoColorPalette(QStringLiteral("primary"), QStringLiteral("#FF0000"), QStringLiteral("#00FF00"));
    const QVariantMap to   = twoColorPalette(QStringLiteral("primary"), QStringLiteral("#0000FF"), QStringLiteral("#FFFF00"));

    const QVariantMap out = ColorUtils::blendPalettes(from, to, 1.0);

    QCOMPARE(out.value(QStringLiteral("primary")).value<QColor>().rgba(), kBlueRgba);
    QCOMPARE(out.value(QStringLiteral("primary2")).value<QColor>().rgba(), 0xFFFFFF00);
}

void TestColorUtils::blendPalettesAcceptsQColorAndStringValues() {
    // variantToColor takes QColor or QString; any other type is invalid.
    QVariantMap from;
    from.insert(QStringLiteral("asColor"), QColor::fromRgba(kRedRgba));
    from.insert(QStringLiteral("asString"), QStringLiteral("#FF0000"));

    QVariantMap to;
    to.insert(QStringLiteral("asColor"), QColor::fromRgba(kBlueRgba));
    to.insert(QStringLiteral("asString"), QStringLiteral("#0000FF"));

    const QVariantMap out = ColorUtils::blendPalettes(from, to, 1.0);

    QCOMPARE(out.value(QStringLiteral("asColor")).value<QColor>().rgba(), kBlueRgba);
    QCOMPARE(out.value(QStringLiteral("asString")).value<QColor>().rgba(), kBlueRgba);
}

void TestColorUtils::hctRoundTripIsExact() {
    const QColor      base = QColor::fromRgba(0xFF3F51B5);
    const QVariantMap hct  = ColorUtils::rgbToHct(base);

    QVERIFY2(qAbs(hct.value(QStringLiteral("h")).toDouble() - 294.8282) < 1e-4, "hue drifted");
    QVERIFY2(qAbs(hct.value(QStringLiteral("c")).toDouble() - 60.9123) < 1e-4, "chroma drifted");
    QVERIFY2(qAbs(hct.value(QStringLiteral("t")).toDouble() - 38.3344) < 1e-4, "tone drifted");

    const QColor back = ColorUtils::hctToRgb(hct.value(QStringLiteral("h")).toDouble(), hct.value(QStringLiteral("c")).toDouble(), hct.value(QStringLiteral("t")).toDouble());
    QCOMPARE(back.rgba(), base.rgba());
}

void TestColorUtils::rgbToHctReturnsExactlyThreeKeys() {
    // Qml/Services/Colours.qml:147,151 indexes these names directly.
    const QVariantMap hct = ColorUtils::rgbToHct(QColor::fromRgba(0xFF3F51B5));

    QCOMPARE(hct.size(), 3);
    QVERIFY(hct.contains(QStringLiteral("h")));
    QVERIFY(hct.contains(QStringLiteral("c")));
    QVERIFY(hct.contains(QStringLiteral("t")));
}

void TestColorUtils::createAnalogousColorWithZeroShiftIsIdentity() {
    QCOMPARE(ColorUtils::createAnalogousColor(QColor::fromRgba(0xFF3F51B5), 0.0).rgba(), 0xFF3F51B5);
}

void TestColorUtils::createAnalogousColorWithFullTurnIsIdentity() {
    // A full 360 degree turn comes back to the base, so the fmod wrap is exact.
    QCOMPARE(ColorUtils::createAnalogousColor(QColor::fromRgba(0xFF3F51B5), 360.0).rgba(), 0xFF3F51B5);
}

void TestColorUtils::createAnalogousColorWrapsNegativeShifts() {
    // -30 must wrap to 330 and give a blue, not a negative hue.
    QCOMPARE(ColorUtils::createAnalogousColor(QColor::fromRgba(0xFF3F51B5), -30.0).rgba(), 0xFF0063BE);
}

void TestColorUtils::createTonalColorIsDarkerForLowTone() {
    // tone < 10 scales chroma by 0.4 (ColorUtils.cpp:146).
    QCOMPARE(ColorUtils::createTonalColor(QColor::fromRgba(0xFF3F51B5), 5.0).rgba(), 0xFF0A0D2E);
}

void TestColorUtils::createTonalColorNearBaseToneKeepsChroma() {
    // tone 40 is in the band where no chroma multiplier applies.
    QCOMPARE(ColorUtils::createTonalColor(QColor::fromRgba(0xFF3F51B5), 40.0).rgba(), 0xFF4455BA);
}

void TestColorUtils::createTonalColorStaysInGamutForExtremeTone() {
    // Gamut mapping reduces chroma rather than clipping components.
    const QColor c = ColorUtils::createTonalColor(QColor::fromRgba(0xFFFF0000), 95.5);

    QVERIFY(c.isValid());
    QVERIFY(c.redF() >= 0.0F && c.redF() <= 1.0F);
    QVERIFY(c.greenF() >= 0.0F && c.greenF() <= 1.0F);
    QVERIFY(c.blueF() >= 0.0F && c.blueF() <= 1.0F);
}

QTEST_GUILESS_MAIN(TestColorUtils)
#include "tst_colorutils.moc"
