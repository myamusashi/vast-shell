#include "LyricsCanvas.hpp"

#include "../Utils/ColorUtils.hpp"

#include <qcolor.h>
#include <qevent.h>
#include <qfont.h>
#include <qlist.h>
#include <qmatrix4x4.h>
#include <qminmax.h>
#include <qnamespace.h>
#include <qnumeric.h>
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
#include <cstddef>
#include <memory>
#include <utility>

namespace {
    constexpr qreal     TRANSLATION_GAP      = 4.0;
    constexpr qreal     SCROLL_SMOOTH_SPEED  = 14.0;
    constexpr qreal     LINE_SMOOTH_SPEED    = 16.0;
    constexpr qreal     INACTIVE_OPACITY     = 0.45;
    constexpr qreal     INACTIVE_SCALE       = 0.9;
    constexpr qreal     TRANSLATION_OPACITY  = 0.7;
    constexpr int       ANIM_INTERVAL_MS     = 16;
    constexpr qreal     VIEWPORT_CULL_MARGIN = 16.0;

    [[nodiscard]] qreal layoutParagraph(QTextLayout& layout, const QString& text, const QFont& font, int horizontalAlignment, qreal availableWidth) {
        layout.clearLayout();
        layout.setText(text);
        layout.setFont(font);

        QTextOption option;
        option.setAlignment(static_cast<Qt::Alignment>(horizontalAlignment));
        option.setWrapMode(QTextOption::WrapAtWordBoundaryOrAnywhere);
        layout.setTextOption(option);

        if (text.isEmpty())
            return 0.0;

        const qreal lineWidth = availableWidth > 0.0 ? availableWidth : 1000000.0;
        qreal       y         = 0.0;

        layout.beginLayout();
        while (true) {
            QTextLine line = layout.createLine();
            if (!line.isValid())
                break;
            line.setLineWidth(lineWidth);
            line.setPosition(QPointF(0.0, y));
            y += line.height();
        }
        layout.endLayout();
        return y;
    }

    class CLineEntrySGNode : public QSGTransformNode {
      public:
        explicit CLineEntrySGNode(QQuickWindow* win) :
            mainOpacityNode(new QSGOpacityNode()), baseTextNode(win->createTextNode()), completedLinesNode(win->createTextNode()), transOpacityNode(new QSGOpacityNode()),
            transTextNode(win->createTextNode()) {
            mainOpacityNode->appendChildNode(baseTextNode);
            mainOpacityNode->appendChildNode(completedLinesNode);
            transOpacityNode->appendChildNode(transTextNode);
            appendChildNode(mainOpacityNode);
            appendChildNode(transOpacityNode);
        }

        void resetContent() {
            baseTextNode->clear();
            completedLinesNode->clear();
            transTextNode->clear();
            for (QSGTextNode* clippedText : std::as_const(clippedTextNodes))
                clippedText->clear();
        }

        QSGOpacityNode*     mainOpacityNode{nullptr};
        QSGTextNode*        baseTextNode{nullptr};
        QSGTextNode*        completedLinesNode{nullptr};
        QList<QSGClipNode*> clipNodes;
        QList<QSGTextNode*> clippedTextNodes;
        QSGOpacityNode*     transOpacityNode{nullptr};
        QSGTextNode*        transTextNode{nullptr};
    };

    class CLyricsCanvasSGNode : public QSGNode {
      public:
        QList<CLineEntrySGNode*> lineNodes;
    };
} // namespace

LyricsCanvas::LyricsCanvas(QQuickItem* parent) : QQuickItem(parent) {
    setFlag(QQuickItem::ItemHasContents, true);
    setAcceptedMouseButtons(Qt::NoButton);

    mAnimTimer.setInterval(ANIM_INTERVAL_MS);
    mAnimTimer.setTimerType(Qt::PreciseTimer);
    connect(&mAnimTimer, &QTimer::timeout, this, &LyricsCanvas::onAnimationTick);
}

QVariantList LyricsCanvas::lines() const {
    return mLines;
}

void LyricsCanvas::setLines(const QVariantList& lines) {
    if (mLines == lines)
        return;
    mLines = lines;
    rebuildEntries();
    Q_EMIT linesChanged();
}

int LyricsCanvas::currentLineIndex() const noexcept {
    return mCurrentLineIndex;
}

void LyricsCanvas::setCurrentLineIndex(int index) {
    if (mCurrentLineIndex == index)
        return;
    mCurrentLineIndex = index;

    if (mCurrentLineIndex >= 0 && static_cast<std::size_t>(mCurrentLineIndex) < mEntries.size()) {
        auto& activeEntry = *mEntries[static_cast<std::size_t>(mCurrentLineIndex)];
        activeEntry.timeline.updatePosition(mPositionMs);
        activeEntry.cachedWordIndex = -1;
    }

    updateTargetScroll(mActive && isVisible() && !mScrollSnapPending);
    Q_EMIT currentLineIndexChanged();
}

qint64 LyricsCanvas::positionMs() const noexcept {
    return mPositionMs;
}

void LyricsCanvas::setPositionMs(qint64 positionMs) {
    if (mPositionMs == positionMs)
        return;
    mPositionMs = positionMs;

    if (mSynced && mCurrentLineIndex >= 0 && static_cast<std::size_t>(mCurrentLineIndex) < mEntries.size()) {
        auto& activeEntry = *mEntries[static_cast<std::size_t>(mCurrentLineIndex)];
        if (activeEntry.timeline.updatePosition(positionMs))
            update();
    }

    Q_EMIT positionMsChanged();
}

bool LyricsCanvas::synced() const noexcept {
    return mSynced;
}

void LyricsCanvas::setSynced(bool synced) {
    if (mSynced == synced)
        return;
    mSynced = synced;
    startAnimationLoop();
    update();
    Q_EMIT syncedChanged();
}

bool LyricsCanvas::active() const noexcept {
    return mActive;
}

void LyricsCanvas::setActive(bool active) {
    if (mActive == active)
        return;
    mActive = active;
    if (mActive) {
        updateTargetScroll(false);
        update();
    } else {
        mAnimTimer.stop();
    }
    Q_EMIT activeChanged();
}

QColor LyricsCanvas::activeColor() const noexcept {
    return mActiveColor;
}

void LyricsCanvas::setActiveColor(const QColor& color) {
    if (!color.isValid() || mActiveColor == color)
        return;
    mActiveColor = color;
    update();
    Q_EMIT activeColorChanged();
}

QColor LyricsCanvas::inactiveColor() const noexcept {
    return mInactiveColor;
}

void LyricsCanvas::setInactiveColor(const QColor& color) {
    if (!color.isValid() || mInactiveColor == color)
        return;
    mInactiveColor = color;
    update();
    Q_EMIT inactiveColorChanged();
}

QColor LyricsCanvas::styleColor() const noexcept {
    return mStyleColor;
}

void LyricsCanvas::setStyleColor(const QColor& color) {
    if (!color.isValid() || mStyleColor == color)
        return;
    mStyleColor = color;
    if (mRaised)
        update();
    Q_EMIT styleColorChanged();
}

QFont LyricsCanvas::font() const {
    return mFont;
}

void LyricsCanvas::setFont(const QFont& font) {
    if (mFont == font)
        return;
    mFont        = font;
    mLayoutDirty = true;
    relayoutEntries();
    Q_EMIT fontChanged();
}

qreal LyricsCanvas::activeFontSize() const noexcept {
    return mActiveFontSize;
}

void LyricsCanvas::setActiveFontSize(qreal size) {
    if (qFuzzyCompare(1.0 + mActiveFontSize, 1.0 + size))
        return;
    mActiveFontSize = size;
    mLayoutDirty    = true;
    relayoutEntries();
    Q_EMIT activeFontSizeChanged();
}

qreal LyricsCanvas::inactiveFontSize() const noexcept {
    return mInactiveFontSize;
}

void LyricsCanvas::setInactiveFontSize(qreal size) {
    if (qFuzzyCompare(1.0 + mInactiveFontSize, 1.0 + size))
        return;
    mInactiveFontSize = size;
    mLayoutDirty      = true;
    relayoutEntries();
    Q_EMIT inactiveFontSizeChanged();
}

int LyricsCanvas::horizontalAlignment() const noexcept {
    return mHorizontalAlignment;
}

void LyricsCanvas::setHorizontalAlignment(int alignment) {
    if (mHorizontalAlignment == alignment)
        return;
    mHorizontalAlignment = alignment;
    mLayoutDirty         = true;
    relayoutEntries();
    Q_EMIT horizontalAlignmentChanged();
}

qreal LyricsCanvas::spacing() const noexcept {
    return mSpacing;
}

void LyricsCanvas::setSpacing(qreal spacing) {
    if (qFuzzyCompare(1.0 + mSpacing, 1.0 + spacing))
        return;
    mSpacing     = spacing;
    mLayoutDirty = true;
    relayoutEntries();
    Q_EMIT spacingChanged();
}

bool LyricsCanvas::raised() const noexcept {
    return mRaised;
}

void LyricsCanvas::setRaised(bool raised) {
    if (mRaised == raised)
        return;
    mRaised = raised;
    update();
    Q_EMIT raisedChanged();
}

void LyricsCanvas::geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);
    const bool widthChanged  = !qFuzzyCompare(1.0 + newGeometry.width(), 1.0 + oldGeometry.width());
    const bool heightChanged = !qFuzzyCompare(1.0 + newGeometry.height(), 1.0 + oldGeometry.height());
    if (widthChanged) {
        mLayoutDirty = true;
        relayoutEntries();
    } else if (heightChanged && newGeometry.height() > 0.0) {
        updateTargetScroll(false);
        update();
    }
}

void LyricsCanvas::wheelEvent(QWheelEvent* event) {
    if (mEntries.empty() || height() <= 0.0) {
        event->ignore();
        return;
    }
    const qreal maxScroll = std::max(0.0, mContentHeight - height());
    const qreal deltaY    = static_cast<qreal>(event->angleDelta().y()) * 0.5;
    mTargetScrollY        = std::clamp(mTargetScrollY - deltaY, 0.0, maxScroll);
    startAnimationLoop();
    event->accept();
}

void LyricsCanvas::rebuildEntries() {
    mAnimTimer.stop();
    mEntries.clear();
    mEntries.reserve(static_cast<std::size_t>(mLines.size()));

    for (qsizetype i = 0; i < mLines.size(); ++i) {
        const QVariantMap map   = mLines.at(i).toMap();
        auto              entry = std::make_unique<SLyricEntry>();
        entry->text             = map.value(QStringLiteral("text")).toString();
        entry->translation      = map.value(QStringLiteral("translation")).toString();
        entry->timeline.rebuild(entry->text, map.value(QStringLiteral("words")).toList());
        entry->timeline.updatePosition(mPositionMs);

        const bool isActive = std::cmp_equal(i, mCurrentLineIndex);
        entry->highlightMix = isActive ? 1.0 : 0.0;
        entry->scale        = isActive ? 1.0 : INACTIVE_SCALE;
        entry->opacity      = !mSynced ? 1.0 : (isActive ? 1.0 : INACTIVE_OPACITY);

        mEntries.push_back(std::move(entry));
    }

    mScrollSnapPending = true;
    mLayoutDirty       = true;
    relayoutEntries();
}

void LyricsCanvas::relayoutEntries() {
    if (width() <= 0.0) {
        mLayoutDirty = true;
        return;
    }

    QFont primaryFont = mFont;
    primaryFont.setPixelSize(std::max(1, qRound(mActiveFontSize)));
    primaryFont.setWeight(QFont::DemiBold);
    primaryFont.setHintingPreference(QFont::PreferNoHinting);
    primaryFont.setVariableAxis(QFont::Tag("wght"), 650.0F);
    primaryFont.setVariableAxis(QFont::Tag("opsz"), static_cast<float>(primaryFont.pixelSize()));

    QFont transFont = mFont;
    transFont.setPixelSize(std::max(1, qRound(mInactiveFontSize)));
    transFont.setWeight(QFont::Normal);
    transFont.setHintingPreference(QFont::PreferNoHinting);

    const qreal availWidth = width();
    qreal       cursorY    = 0.0;

    for (std::size_t i = 0; i < mEntries.size(); ++i) {
        auto& entry           = *mEntries[i];
        entry.cachedWordIndex = -1;
        entry.topY            = cursorY;
        entry.textHeight      = layoutParagraph(entry.textLayout, entry.text, primaryFont, mHorizontalAlignment, availWidth);

        if (!entry.translation.isEmpty()) {
            const QString wrappedTrans = QStringLiteral("(") + entry.translation + QStringLiteral(")");
            entry.translationHeight    = layoutParagraph(entry.translationLayout, wrappedTrans, transFont, mHorizontalAlignment, availWidth);
            entry.totalHeight          = entry.textHeight + TRANSLATION_GAP + entry.translationHeight;
        } else {
            entry.translationLayout.clearLayout();
            entry.translationHeight = 0.0;
            entry.totalHeight       = entry.textHeight;
        }

        cursorY += entry.totalHeight;
        if (i + 1 < mEntries.size())
            cursorY += mSpacing;
    }

    mContentHeight = cursorY;
    mLayoutDirty   = false;
    setImplicitHeight(mContentHeight);

    updateTargetScroll(!mScrollSnapPending && mActive && isVisible());
    update();
}

void LyricsCanvas::updateTargetScroll(bool animate) {
    if (mEntries.empty() || mCurrentLineIndex < 0 || static_cast<std::size_t>(mCurrentLineIndex) >= mEntries.size()) {
        mTargetScrollY = 0.0;
    } else if (height() > 0.0) {
        const auto& activeEntry  = *mEntries[static_cast<std::size_t>(mCurrentLineIndex)];
        const qreal centerOffset = activeEntry.topY + activeEntry.totalHeight * 0.5 - height() * 0.5;
        const qreal maxScroll    = std::max(0.0, mContentHeight - height());
        mTargetScrollY           = std::clamp(centerOffset, 0.0, maxScroll);
    }

    if (!animate || height() <= 0.0 || !mActive || !isVisible()) {
        mScrollY = mTargetScrollY;
        for (std::size_t i = 0; i < mEntries.size(); ++i) {
            auto&      entry    = *mEntries[i];
            const bool isActive = std::cmp_equal(i, mCurrentLineIndex);
            entry.highlightMix  = isActive ? 1.0 : 0.0;
            entry.scale         = isActive ? 1.0 : INACTIVE_SCALE;
            entry.opacity       = !mSynced ? 1.0 : (isActive ? 1.0 : INACTIVE_OPACITY);
        }
        if (height() > 0.0 && width() > 0.0)
            mScrollSnapPending = false;
        mAnimTimer.stop();
        update();
        return;
    }

    startAnimationLoop();
}

void LyricsCanvas::startAnimationLoop() {
    if (!mActive || !isVisible())
        return;
    if (!mAnimTimer.isActive()) {
        mAnimClock.restart();
        mAnimTimer.start();
    }
}

void LyricsCanvas::onAnimationTick() {
    const qint64 elapsedNs = mAnimClock.nsecsElapsed();
    mAnimClock.restart();
    const qreal dt          = std::clamp(static_cast<qreal>(elapsedNs) * 1e-9, 0.001, 0.05);
    const qreal scrollAlpha = 1.0 - std::exp(-SCROLL_SMOOTH_SPEED * dt);
    const qreal lineAlpha   = 1.0 - std::exp(-LINE_SMOOTH_SPEED * dt);

    bool        stillMoving = false;

    if (std::abs(mScrollY - mTargetScrollY) > 0.25) {
        mScrollY += (mTargetScrollY - mScrollY) * scrollAlpha;
        stillMoving = true;
    } else {
        mScrollY = mTargetScrollY;
    }

    for (std::size_t i = 0; i < mEntries.size(); ++i) {
        auto&       entry         = *mEntries[i];
        const bool  isActive      = std::cmp_equal(i, mCurrentLineIndex);
        const qreal targetMix     = isActive ? 1.0 : 0.0;
        const qreal targetScale   = isActive ? 1.0 : INACTIVE_SCALE;
        const qreal targetOpacity = !mSynced ? 1.0 : (isActive ? 1.0 : INACTIVE_OPACITY);

        if (std::abs(entry.highlightMix - targetMix) > 0.002) {
            entry.highlightMix += (targetMix - entry.highlightMix) * lineAlpha;
            stillMoving = true;
        } else {
            entry.highlightMix = targetMix;
        }

        if (std::abs(entry.scale - targetScale) > 0.001) {
            entry.scale += (targetScale - entry.scale) * lineAlpha;
            stillMoving = true;
        } else {
            entry.scale = targetScale;
        }

        if (std::abs(entry.opacity - targetOpacity) > 0.002) {
            entry.opacity += (targetOpacity - entry.opacity) * lineAlpha;
            stillMoving = true;
        } else {
            entry.opacity = targetOpacity;
        }
    }

    if (!stillMoving)
        mAnimTimer.stop();

    update();
}

void LyricsCanvas::ensureWordCache(SLyricEntry& entry, qsizetype activeWordIndex) {
    if (entry.cachedWordIndex == activeWordIndex)
        return;

    const int textLength = static_cast<int>(entry.text.length());
    vast::lyric_render::buildWordSegments(entry.textLayout, entry.timeline.wordAt(activeWordIndex), textLength, entry.cachedWordStart, entry.cachedWordEnd, entry.cachedTotalWidth,
                                          entry.cachedSegments);
    entry.cachedWordIndex = activeWordIndex;
}

QSGNode* LyricsCanvas::updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* /*updatePaintNodeData*/) {
    QQuickWindow* win = window();
    if (win == nullptr || mEntries.empty() || width() <= 0.0) {
        delete oldNode;
        return nullptr;
    }

    if (mLayoutDirty)
        relayoutEntries();

    auto* rootNode = dynamic_cast<CLyricsCanvasSGNode*>(oldNode);
    if (rootNode == nullptr)
        rootNode = new CLyricsCanvasSGNode();

    const QColor safeActive   = mActiveColor.isValid() ? mActiveColor : QColor(Qt::white);
    const QColor safeInactive = mInactiveColor.isValid() ? mInactiveColor : QColor(Qt::gray);
    const QColor safeStyle    = mStyleColor.isValid() ? mStyleColor : QColor(0, 0, 0, 128);
    const qreal  viewHeight   = height();
    const qreal  viewWidth    = width();

    qsizetype    usedNodes = 0;

    for (std::size_t i = 0; i < mEntries.size(); ++i) {
        auto&       entry             = *mEntries[i];
        const qreal entryScreenTop    = entry.topY - mScrollY;
        const qreal entryScreenBottom = entryScreenTop + entry.totalHeight;

        if (entryScreenBottom < -VIEWPORT_CULL_MARGIN || entryScreenTop > viewHeight + VIEWPORT_CULL_MARGIN)
            continue;

        if (usedNodes >= rootNode->lineNodes.size()) {
            auto* newLineNode = new CLineEntrySGNode(win);
            rootNode->appendChildNode(newLineNode);
            rootNode->lineNodes.append(newLineNode);
        }

        CLineEntrySGNode* lineNode = rootNode->lineNodes.at(usedNodes);
        ++usedNodes;
        lineNode->resetContent();

        QMatrix4x4 matrix;
        matrix.translate(0.0F, static_cast<float>(entryScreenTop));
        if (!qFuzzyCompare(1.0 + entry.scale, 2.0)) {
            const auto cx = static_cast<float>(viewWidth * 0.5);
            const auto cy = static_cast<float>(entry.totalHeight * 0.5);
            const auto s  = static_cast<float>(entry.scale);
            matrix.translate(cx, cy);
            matrix.scale(s, s);
            matrix.translate(-cx, -cy);
        }
        lineNode->setMatrix(matrix);
        lineNode->mainOpacityNode->setOpacity(entry.opacity);

        const bool   isActiveLine    = std::cmp_equal(i, mCurrentLineIndex);
        const QColor effectiveActive = (entry.highlightMix >= 0.999) ? safeActive :
            (entry.highlightMix <= 0.001)                            ? safeInactive :
                                                                       ColorUtils::blendColors(safeInactive, safeActive, entry.highlightMix);

        if (!mSynced || !isActiveLine || entry.timeline.isEmpty()) {
            vast::lyric_render::configureTextNode(lineNode->baseTextNode, effectiveActive, mRaised, safeStyle);
            lineNode->baseTextNode->addTextLayout(QPointF(0.0, 0.0), &entry.textLayout);
        } else {
            entry.timeline.updatePosition(mPositionMs);
            const qsizetype activeIdx = entry.timeline.activeWordIndex();

            vast::lyric_render::configureTextNode(lineNode->baseTextNode, safeInactive, mRaised, safeStyle);
            lineNode->baseTextNode->addTextLayout(QPointF(0.0, 0.0), &entry.textLayout);

            if (activeIdx >= 0) {
                ensureWordCache(entry, activeIdx);
                const double progress = entry.timeline.activeWordProgress(mPositionMs);

                vast::lyric_render::ensureClipNodePool(lineNode->clipNodes, lineNode->clippedTextNodes, entry.cachedSegments.size(), lineNode->mainOpacityNode, win);
                vast::lyric_render::populateActiveWordNodes(entry.textLayout, 0.0, entry.cachedWordStart, entry.cachedTotalWidth, progress, entry.cachedSegments, effectiveActive,
                                                            mRaised, safeStyle, lineNode->completedLinesNode, lineNode->clipNodes, lineNode->clippedTextNodes);
            }
        }

        if (!entry.translation.isEmpty() && entry.translationHeight > 0.0 && entry.translationLayout.lineCount() > 0) {
            lineNode->transOpacityNode->setOpacity(entry.opacity * TRANSLATION_OPACITY);
            vast::lyric_render::configureTextNode(lineNode->transTextNode, effectiveActive, mRaised, safeStyle);
            lineNode->transTextNode->addTextLayout(QPointF(0.0, entry.textHeight + TRANSLATION_GAP), &entry.translationLayout);
        }
    }

    for (qsizetype idx = usedNodes; idx < rootNode->lineNodes.size(); ++idx)
        rootNode->lineNodes.at(idx)->resetContent();

    return rootNode;
}
