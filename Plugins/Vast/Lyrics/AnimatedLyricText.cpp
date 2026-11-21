#include "AnimatedLyricText.hpp"

#include "../Utils/ColorUtils.hpp"

#include <qcolor.h>
#include <qfont.h>
#include <qlist.h>
#include <qnamespace.h>
#include <qpoint.h>
#include <qquickitem.h>
#include <qquickwindow.h>
#include <qrect.h>
#include <qsggeometry.h>
#include <qsgnode.h>
#include <qsgtextnode.h>
#include <qsgtexture.h>
#include <qstring.h>
#include <qtextlayout.h>
#include <qtextoption.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include <algorithm>
#include <cmath>

namespace {
    [[nodiscard]] QTextOption::WrapMode mapWrapMode(int wrapMode) noexcept {
        switch (wrapMode) {
            case 0: return QTextOption::NoWrap;
            case 1: return QTextOption::WordWrap;
            case 2: return QTextOption::WrapAnywhere;
            default: return QTextOption::WrapAtWordBoundaryOrAnywhere;
        }
    }

    // Scene Graph node container owned by Qt Quick's render loop.
    class CAnimatedLyricSGNode : public QSGNode {
      public:
        QSGTextNode*        baseNode{nullptr};
        QSGTextNode*        completedLinesNode{nullptr};
        QList<QSGClipNode*> clipNodes;
        QList<QSGTextNode*> clippedTextNodes;
    };
} // namespace

AnimatedLyricText::AnimatedLyricText(QQuickItem* parent) : QQuickItem(parent) {
    setFlag(QQuickItem::ItemHasContents, true);
}

QString AnimatedLyricText::text() const {
    return mText;
}

void AnimatedLyricText::setText(const QString& text) {
    if (mText == text)
        return;
    mText = text;
    rebuildTimeline();
    relayout();
    Q_EMIT textChanged();
}

QVariantList AnimatedLyricText::words() const {
    return mWords;
}

void AnimatedLyricText::setWords(const QVariantList& words) {
    if (mWords == words)
        return;
    mWords = words;
    rebuildTimeline();
    update();
    Q_EMIT wordsChanged();
}

qint64 AnimatedLyricText::positionMs() const noexcept {
    return mPositionMs;
}

void AnimatedLyricText::setPositionMs(qint64 positionMs) {
    if (mPositionMs == positionMs)
        return;
    mPositionMs        = positionMs;
    const bool changed = mTimeline.updatePosition(positionMs);
    if (changed && mSynced && !mTimeline.isEmpty() && mHighlightMix > 0.001)
        update();
    Q_EMIT positionMsChanged();
}

bool AnimatedLyricText::synced() const noexcept {
    return mSynced;
}

void AnimatedLyricText::setSynced(bool synced) {
    if (mSynced == synced)
        return;
    mSynced = synced;
    update();
    Q_EMIT syncedChanged();
}

bool AnimatedLyricText::active() const noexcept {
    return mActive;
}

void AnimatedLyricText::setActive(bool active) {
    if (mActive == active)
        return;
    mActive = active;
    if (mActive) {
        mTimeline.updatePosition(mPositionMs);
        invalidateActiveWordCache();
    }
    update();
    Q_EMIT activeChanged();
}

qreal AnimatedLyricText::highlightMix() const noexcept {
    return mHighlightMix;
}

void AnimatedLyricText::setHighlightMix(qreal highlightMix) {
    const qreal clamped = std::clamp(highlightMix, 0.0, 1.0);
    if (qFuzzyCompare(1.0 + mHighlightMix, 1.0 + clamped))
        return;
    mHighlightMix = clamped;
    update();
    Q_EMIT highlightMixChanged();
}

QColor AnimatedLyricText::activeColor() const noexcept {
    return mActiveColor;
}

void AnimatedLyricText::setActiveColor(const QColor& color) {
    if (!color.isValid() || mActiveColor == color)
        return;
    mActiveColor = color;
    update();
    Q_EMIT activeColorChanged();
}

QColor AnimatedLyricText::inactiveColor() const noexcept {
    return mInactiveColor;
}

void AnimatedLyricText::setInactiveColor(const QColor& color) {
    if (!color.isValid() || mInactiveColor == color)
        return;
    mInactiveColor = color;
    update();
    Q_EMIT inactiveColorChanged();
}

QFont AnimatedLyricText::font() const {
    return mFont;
}

void AnimatedLyricText::setFont(const QFont& font) {
    if (mFont == font)
        return;
    mFont = font;
    relayout();
    Q_EMIT fontChanged();
}

int AnimatedLyricText::horizontalAlignment() const noexcept {
    return mHorizontalAlignment;
}

void AnimatedLyricText::setHorizontalAlignment(int alignment) {
    if (mHorizontalAlignment == alignment)
        return;
    mHorizontalAlignment = alignment;
    relayout();
    Q_EMIT horizontalAlignmentChanged();
}

int AnimatedLyricText::wrapMode() const noexcept {
    return mWrapMode;
}

void AnimatedLyricText::setWrapMode(int wrapMode) {
    if (mWrapMode == wrapMode)
        return;
    mWrapMode = wrapMode;
    relayout();
    Q_EMIT wrapModeChanged();
}

bool AnimatedLyricText::raised() const noexcept {
    return mRaised;
}

void AnimatedLyricText::setRaised(bool raised) {
    if (mRaised == raised)
        return;
    mRaised = raised;
    update();
    Q_EMIT raisedChanged();
}

QColor AnimatedLyricText::styleColor() const noexcept {
    return mStyleColor;
}

void AnimatedLyricText::setStyleColor(const QColor& color) {
    if (!color.isValid() || mStyleColor == color)
        return;
    mStyleColor = color;
    if (mRaised)
        update();
    Q_EMIT styleColorChanged();
}

void AnimatedLyricText::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    if (!qFuzzyCompare(1.0 + newGeometry.width(), 1.0 + oldGeometry.width()))
        relayout();
}

void AnimatedLyricText::invalidateActiveWordCache() noexcept {
    mSegmentCacheValid = false;
}

void AnimatedLyricText::ensureActiveWordCache(qsizetype activeWordIndex, int textLength) {
    if (mSegmentCacheValid && mCachedActiveWordIndex == activeWordIndex)
        return;

    vast::lyric_render::buildWordSegments(mLayout, mTimeline.wordAt(activeWordIndex), textLength, mCachedWordStart, mCachedWordEnd, mCachedTotalWidth, mCachedSegments);
    mCachedActiveWordIndex = activeWordIndex;
    mSegmentCacheValid     = true;
}

void AnimatedLyricText::rebuildTimeline() {
    mTimeline.rebuild(mText, mWords);
    mTimeline.updatePosition(mPositionMs);
    invalidateActiveWordCache();
}

void AnimatedLyricText::relayout() {
    invalidateActiveWordCache();
    mLayout.clearLayout();
    mLayout.setText(mText);
    mLayout.setFont(mFont);

    QTextOption option;
    option.setAlignment(static_cast<Qt::Alignment>(mHorizontalAlignment));
    option.setWrapMode(mapWrapMode(mWrapMode));
    mLayout.setTextOption(option);

    const bool  noWrap         = (mWrapMode == 0);
    const qreal availableWidth = (!noWrap && width() > 0.0) ? width() : 1000000.0;
    qreal       maxLineWidth   = 0.0;
    qreal       y              = 0.0;

    mLayout.beginLayout();
    while (true) {
        QTextLine line = mLayout.createLine();
        if (!line.isValid())
            break;
        line.setLineWidth(noWrap && width() > 0.0 ? width() : availableWidth);
        line.setPosition(QPointF(0.0, y));
        y += line.height();
        maxLineWidth = std::max(maxLineWidth, line.naturalTextWidth());
    }
    mLayout.endLayout();

    mLayoutHeight = y;
    setImplicitSize(maxLineWidth, y);
    update();
}

QSGNode* AnimatedLyricText::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* /*updatePaintNodeData*/) {
    QQuickWindow* win = window();
    if (mText.isEmpty() || win == nullptr || mLayout.lineCount() == 0) {
        delete oldNode;
        return nullptr;
    }

    auto* rootNode = dynamic_cast<CAnimatedLyricSGNode*>(oldNode);
    if (rootNode == nullptr) {
        rootNode                     = new CAnimatedLyricSGNode();
        rootNode->baseNode           = win->createTextNode();
        rootNode->completedLinesNode = win->createTextNode();
        rootNode->appendChildNode(rootNode->baseNode);
        rootNode->appendChildNode(rootNode->completedLinesNode);
    }

    const QColor safeActive      = mActiveColor.isValid() ? mActiveColor : QColor(Qt::white);
    const QColor safeInactive    = mInactiveColor.isValid() ? mInactiveColor : QColor(Qt::gray);
    const QColor safeStyle       = mStyleColor.isValid() ? mStyleColor : QColor(Qt::black);
    const qreal  yOffset         = (mWrapMode == 0 && height() > mLayoutHeight) ? (height() - mLayoutHeight) * 0.5 : 0.0;
    const QColor effectiveActive = (mHighlightMix >= 0.999) ? safeActive :
        (mHighlightMix <= 0.001)                            ? safeInactive :
                                                              ColorUtils::blendColors(safeInactive, safeActive, mHighlightMix);

    rootNode->completedLinesNode->clear();
    for (QSGTextNode* clippedText : std::as_const(rootNode->clippedTextNodes))
        clippedText->clear();

    if (!mSynced || !mActive || mTimeline.isEmpty() || mHighlightMix <= 0.001) {
        vast::lyric_render::configureTextNode(rootNode->baseNode, effectiveActive, mRaised, safeStyle);
        rootNode->baseNode->addTextLayout(QPointF(0.0, yOffset), &mLayout);
        return rootNode;
    }

    const qsizetype activeIdx = mTimeline.activeWordIndex();
    vast::lyric_render::configureTextNode(rootNode->baseNode, safeInactive, mRaised, safeStyle);
    rootNode->baseNode->addTextLayout(QPointF(0.0, yOffset), &mLayout);

    if (activeIdx < 0)
        return rootNode;

    const int textLen = static_cast<int>(mText.length());
    ensureActiveWordCache(activeIdx, textLen);
    const double progress = mTimeline.activeWordProgress(mPositionMs);

    vast::lyric_render::ensureClipNodePool(rootNode->clipNodes, rootNode->clippedTextNodes, mCachedSegments.size(), rootNode, win);
    vast::lyric_render::populateActiveWordNodes(mLayout, yOffset, mCachedWordStart, mCachedTotalWidth, progress, mCachedSegments, effectiveActive, mRaised, safeStyle,
                                                rootNode->completedLinesNode, rootNode->clipNodes, rootNode->clippedTextNodes);

    return rootNode;
}
