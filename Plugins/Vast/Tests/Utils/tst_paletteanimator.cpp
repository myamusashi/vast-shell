#include <qcolor.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariantmap.h>

#include <memory>

#include "../../Utils/ColorUtils.hpp"
#include "../../Utils/PaletteAnimator.hpp"

namespace {

    [[nodiscard]] QVariantMap uniformPalette(const char* hex) {
        QVariantMap m;
        m.insert(QStringLiteral("primary"), QString::fromLatin1(hex));
        return m;
    }

    [[nodiscard]] QColor primaryOf(const QVariantMap& palette) {
        return palette.value(QStringLiteral("primary")).value<QColor>();
    }

    // Drives the animation to a progress without waiting. stop() first: a running animation advances
    // on its own clock.
    void driveTo(PaletteAnimator& animator, int timeMs) {
        animator.animation()->stop();
        animator.animation()->setCurrentTime(timeMs);
    }

    void settle(PaletteAnimator& animator) {
        driveTo(animator, animator.duration());
    }

    constexpr qreal kEasedHalf    = 0.875;    // OutCubic(0.5) on a 300 ms animation
    constexpr qreal kEasedQuarter = 0.578125; // OutCubic(0.25)

} // namespace

class TestPaletteAnimator : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void init();

    void durationDefaultsTo300();
    void setDurationStoresAndSignals();
    void currentPaletteStartsEmpty();
    void aSettledTransitionReproducesTheTargetExactly();
    void theFirstTransitionIsIndependentOfProgressBecauseTheSourceIsEmpty();
    void interpolatesAtTheEasedMidpoint();
    void interpolatedValueSitsBetweenTheEndpoints();
    void transitionToRestartsFromTheCurrentIntermediateFrame();
    void transitionToEmitsCurrentPaletteChanged();

  private:
    std::unique_ptr<PaletteAnimator> mAnimator;
};

void TestPaletteAnimator::init() {
    mAnimator = std::make_unique<PaletteAnimator>();
}

void TestPaletteAnimator::durationDefaultsTo300() {
    // PaletteAnimator.cpp:7.
    QCOMPARE(mAnimator->duration(), 300);
}

void TestPaletteAnimator::setDurationStoresAndSignals() {
    QSignalSpy spy(mAnimator.get(), &PaletteAnimator::durationChanged);

    mAnimator->setDuration(500);

    QCOMPARE(mAnimator->duration(), 500);
    QCOMPARE(spy.count(), 1);
}

void TestPaletteAnimator::currentPaletteStartsEmpty() {
    // PaletteAnimator.cpp:35 leaves mCurrent default-constructed.
    QVERIFY(mAnimator->currentPalette().isEmpty());
}

void TestPaletteAnimator::aSettledTransitionReproducesTheTargetExactly() {
    mAnimator->transitionTo(uniformPalette("#FF0000"));
    settle(*mAnimator);

    // Eased progress at the end is 1.0, so the blend is the target.
    QCOMPARE(primaryOf(mAnimator->currentPalette()).rgba(), 0xFFFF0000);
}

void TestPaletteAnimator::theFirstTransitionIsIndependentOfProgressBecauseTheSourceIsEmpty() {
    mAnimator->transitionTo(uniformPalette("#FF0000"));

    // mCurrent is empty, so mFrom has no keys and every progress yields the target. Drive to non-zero
    // times: setCurrentTime(0) on an animation already at 0 emits nothing.
    driveTo(*mAnimator, 150);
    QCOMPARE(primaryOf(mAnimator->currentPalette()).rgba(), 0xFFFF0000);

    driveTo(*mAnimator, 299);
    QCOMPARE(primaryOf(mAnimator->currentPalette()).rgba(), 0xFFFF0000);
}

void TestPaletteAnimator::interpolatesAtTheEasedMidpoint() {
    // Two transitions; the first is degenerate.
    mAnimator->transitionTo(uniformPalette("#FF0000"));
    settle(*mAnimator);

    mAnimator->transitionTo(uniformPalette("#0000FF"));
    driveTo(*mAnimator, 150);

    // Asserted against the call: the contract is blending with the eased progress.
    const QColor expected = ColorUtils::blendColors(QColor::fromRgba(0xFFFF0000), QColor::fromRgba(0xFF0000FF), kEasedHalf);
    QCOMPARE(primaryOf(mAnimator->currentPalette()), expected);
}

void TestPaletteAnimator::interpolatedValueSitsBetweenTheEndpoints() {
    mAnimator->transitionTo(uniformPalette("#FF0000"));
    settle(*mAnimator);
    mAnimator->transitionTo(uniformPalette("#0000FF"));

    driveTo(*mAnimator, 75);
    const QColor atQuarter = primaryOf(mAnimator->currentPalette());

    driveTo(*mAnimator, 150);
    const QColor atHalf = primaryOf(mAnimator->currentPalette());

    const QColor from(0xFFFF0000);
    const QColor to(0xFF0000FF);

    // Genuinely progressing, not snapping to an endpoint.
    QVERIFY(atQuarter != from);
    QVERIFY(atQuarter != to);
    QVERIFY(atQuarter != atHalf);
    QCOMPARE(atQuarter, ColorUtils::blendColors(from, to, kEasedQuarter));
}

void TestPaletteAnimator::transitionToRestartsFromTheCurrentIntermediateFrame() {
    mAnimator->transitionTo(uniformPalette("#FF0000"));
    settle(*mAnimator);

    mAnimator->transitionTo(uniformPalette("#0000FF"));
    driveTo(*mAnimator, 150);
    const QColor midway = primaryOf(mAnimator->currentPalette());
    QVERIFY(midway != QColor::fromRgba(0xFFFF0000));

    // Interrupting mid-flight blends from the last interpolated frame (PaletteAnimator.cpp:18-23).
    mAnimator->transitionTo(uniformPalette("#00FF00"));
    settle(*mAnimator);

    QCOMPARE(primaryOf(mAnimator->currentPalette()).rgba(), 0xFF00FF00);
}

void TestPaletteAnimator::transitionToEmitsCurrentPaletteChanged() {
    QSignalSpy spy(mAnimator.get(), &PaletteAnimator::currentPaletteChanged);

    mAnimator->transitionTo(uniformPalette("#FF0000"));
    settle(*mAnimator);

    QVERIFY2(spy.count() >= 1, "settling a transition must report the new palette");
}

QTEST_GUILESS_MAIN(TestPaletteAnimator)
#include "tst_paletteanimator.moc"
