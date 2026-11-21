#include "AnimatedLyricText.hpp"

#include "../Utils/ColorUtils.hpp"

#include <qbrush.h>
#include <qcolor.h>
#include <qfont.h>
#include <qlist.h>
#include <qnamespace.h>
#include <qpainter.h>
#include <qpoint.h>
#include <qquickitem.h>
#include <qquickpainteditem.h>
#include <qrect.h>
#include <qstring.h>
#include <qtextformat.h>
#include <qtextlayout.h>
#include <qtextoption.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include <algorithm>
#include <cmath>
#include <utility>

namespace {
    [[nodiscard]] QTextOption::WrapMode mapWrapMode(int wrapMode) noexcept {
        switch (wrapMode) {
            case 0: return QTextOption::NoWrap;
            case 1: return QTextOption::WordWrap;
            case 2: return QTextOption::WrapAnywhere;
            default: return QTextOption::WrapAtWordBoundaryOrAnywhere;
        }
    }

    [[nodiscard]] QTextLayout::FormatRange makeRange(int start, int length, const QColor& color) {
        QTextCharFormat fmt;
        fmt.setForeground(QBrush(color));
        return {.start = start, .length = length, .format = fmt};
    }
} // namespace

AnimatedLyricText::AnimatedLyricText(QQuickItem* parent) : QQuickPaintedItem(parent) {
    setAntialiasing(true);
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
    if (mActiveColor == color)
        return;
    mActiveColor = color;
    update();
    Q_EMIT activeColorChanged();
}

QColor AnimatedLyricText::inactiveColor() const noexcept {
    return mInactiveColor;
}

void AnimatedLyricText::setInactiveColor(const QColor& color) {
    if (mInactiveColor == color)
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
    if (mStyleColor == color)
        return;
    mStyleColor = color;
    if (mRaised)
        update();
    Q_EMIT styleColorChanged();
}

void AnimatedLyricText::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickPaintedItem::geometryChange(newGeometry, oldGeometry);
    if (!qFuzzyCompare(1.0 + newGeometry.width(), 1.0 + oldGeometry.width()))
        relayout();
}

void AnimatedLyricText::invalidateActiveWordCache() noexcept {
    mSegmentCacheValid    = false;
    mFillRangesCacheValid = false;
}

void AnimatedLyricText::ensureActiveWordCache(qsizetype activeWordIndex, int textLength, const QColor& effectiveActive) {
    if (!mSegmentCacheValid || mCachedActiveWordIndex != activeWordIndex) {
        const auto& activeWord = mTimeline.wordAt(activeWordIndex);
        mCachedWordStart       = std::clamp(activeWord.charStart, 0, textLength);
        mCachedWordEnd         = std::clamp(activeWord.charStart + activeWord.charLength, mCachedWordStart, textLength);
        mCachedSegments.clear();
        mCachedTotalWidth = 0.0;

        if (mCachedWordEnd > mCachedWordStart) {
            const int lineCount = mLayout.lineCount();
            for (int lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
                const QTextLine line      = mLayout.lineAt(lineIndex);
                const int       lineStart = line.textStart();
                const int       lineEnd   = lineStart + line.textLength();
                if (lineEnd <= mCachedWordStart || lineStart >= mCachedWordEnd)
                    continue;
                const int   segmentStart = std::max(mCachedWordStart, lineStart);
                const int   segmentEnd   = std::min(mCachedWordEnd, lineEnd);
                const qreal leftCursor   = line.cursorToX(segmentStart);
                const qreal rightCursor  = line.cursorToX(segmentEnd);
                const qreal segmentWidth = std::abs(rightCursor - leftCursor);
                if (segmentWidth <= 0.0)
                    continue;
                mCachedSegments.append({
                    .leftX  = std::min(leftCursor, rightCursor),
                    .width  = segmentWidth,
                    .topY   = line.y(),
                    .height = line.height(),
                });
                mCachedTotalWidth += segmentWidth;
            }
        }

        mCachedActiveWordIndex = activeWordIndex;
        mSegmentCacheValid     = true;
        mFillRangesCacheValid  = false;
    }

    if (!mFillRangesCacheValid || mCachedFillColor != effectiveActive) {
        mCachedFillRanges.clear();
        if (mCachedWordEnd > mCachedWordStart) {
            if (mCachedWordStart > 0)
                mCachedFillRanges.append(makeRange(0, mCachedWordStart, Qt::transparent));
            mCachedFillRanges.append(makeRange(mCachedWordStart, mCachedWordEnd - mCachedWordStart, effectiveActive));
            if (mCachedWordEnd < textLength)
                mCachedFillRanges.append(makeRange(mCachedWordEnd, textLength - mCachedWordEnd, Qt::transparent));
        }
        mCachedFillColor      = effectiveActive;
        mFillRangesCacheValid = true;
    }
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

void AnimatedLyricText::paint(QPainter* painter) {
    if (mText.isEmpty() || painter == nullptr)
        return;

    painter->setRenderHint(QPainter::TextAntialiasing, true);

    const int   textLen = static_cast<int>(mText.length());
    const qreal yOffset = (mWrapMode == 0 && height() > mLayoutHeight) ? (height() - mLayoutHeight) * 0.5 : 0.0;

    if (mRaised && mStyleColor.alpha() > 0) {
        const QList<QTextLayout::FormatRange> shadowRanges{makeRange(0, textLen, mStyleColor)};
        mLayout.draw(painter, QPointF(0.0, yOffset + 1.0), shadowRanges);
    }

    QList<QTextLayout::FormatRange> ranges;
    if (!mSynced || mTimeline.isEmpty() || mHighlightMix <= 0.001) {
        const QColor flatColor = (!mSynced && mActive && mHighlightMix > 0.001) ? ColorUtils::blendColors(mInactiveColor, mActiveColor, mHighlightMix) : mInactiveColor;
        ranges.append(makeRange(0, textLen, flatColor));
        mLayout.draw(painter, QPointF(0.0, yOffset), ranges);
        return;
    }

    const qsizetype activeIdx       = mTimeline.activeWordIndex();
    const QColor    effectiveActive = (mHighlightMix >= 0.999) ? mActiveColor : ColorUtils::blendColors(mInactiveColor, mActiveColor, mHighlightMix);

    if (activeIdx < 0) {
        ranges.append(makeRange(0, textLen, mInactiveColor));
        mLayout.draw(painter, QPointF(0.0, yOffset), ranges);
        return;
    }

    ensureActiveWordCache(activeIdx, textLen, effectiveActive);
    const double progress  = mTimeline.activeWordProgress(mPositionMs);
    const int    wordStart = mCachedWordStart;
    const int    wordEnd   = mCachedWordEnd;

    if (progress >= 1.0) {
        if (wordEnd > 0)
            ranges.append(makeRange(0, wordEnd, effectiveActive));
        if (wordEnd < textLen)
            ranges.append(makeRange(wordEnd, textLen - wordEnd, mInactiveColor));
        mLayout.draw(painter, QPointF(0.0, yOffset), ranges);
        return;
    }

    // Base pass: words before the active word are activeColor; active + later words are inactiveColor.
    if (wordStart > 0)
        ranges.append(makeRange(0, wordStart, effectiveActive));
    if (wordStart < textLen)
        ranges.append(makeRange(wordStart, textLen - wordStart, mInactiveColor));
    mLayout.draw(painter, QPointF(0.0, yOffset), ranges);

    if (progress <= 0.0 || wordEnd <= wordStart || mCachedTotalWidth <= 0.0)
        return;

    // Left-to-right clipped fill across the active word inside [startTime, endTime].
    qreal remainingFill = mCachedTotalWidth * progress;
    for (const LineSegment& segment : std::as_const(mCachedSegments)) {
        if (remainingFill <= 0.0)
            break;
        const qreal clipWidth = std::min(segment.width, remainingFill);
        painter->save();
        painter->setClipRect(QRectF(segment.leftX, yOffset + segment.topY, clipWidth, segment.height), Qt::IntersectClip);
        mLayout.draw(painter, QPointF(0.0, yOffset), mCachedFillRanges);
        painter->restore();
        remainingFill -= clipWidth;
    }
}
