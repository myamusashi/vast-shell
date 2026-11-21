#pragma once

#include <qcolor.h>
#include <qlist.h>
#include <qpoint.h>
#include <qquickwindow.h>
#include <qrect.h>
#include <qsggeometry.h>
#include <qsgnode.h>
#include <qsgtextnode.h>
#include <qsgtexture.h>
#include <qtextlayout.h>
#include <qtypes.h>

#include <algorithm>
#include <cmath>

#include "LyricsTimeline.hpp"

namespace vast::lyric_render {

    struct SLineSegment {
        int   lineIndex{0};
        qreal leftX{0.0};
        qreal width{0.0};
        qreal topY{0.0};
        qreal height{0.0};
    };

    inline void configureTextNode(QSGTextNode* node, const QColor& color, bool raised, const QColor& styleColor) {
        node->clear();
        node->setColor(color);
        node->setTextStyle(raised ? QSGTextNode::Raised : QSGTextNode::Normal);
        node->setStyleColor(styleColor);
        node->setFiltering(QSGTexture::Linear);
    }

    inline void ensureClipNodePool(QList<QSGClipNode*>& clipNodes, QList<QSGTextNode*>& clippedTextNodes, qsizetype requiredCount, QSGNode* parentNode, QQuickWindow* win) {
        while (clipNodes.size() < requiredCount) {
            auto* clipNode = new QSGClipNode();
            clipNode->setIsRectangular(true);
            auto* geom = new QSGGeometry(QSGGeometry::defaultAttributes_Point2D(), 4);
            clipNode->setGeometry(geom);
            clipNode->setFlag(QSGNode::OwnsGeometry, true);

            auto* textNode = win->createTextNode();
            clipNode->appendChildNode(textNode);
            parentNode->appendChildNode(clipNode);
            clipNodes.append(clipNode);
            clippedTextNodes.append(textNode);
        }
    }

    inline void buildWordSegments(const QTextLayout& layout, const LyricsTimeline::WordTiming& activeWord, int textLength, int& outWordStart, int& outWordEnd, qreal& outTotalWidth,
                                  QList<SLineSegment>& outSegments) {
        outWordStart = std::clamp(activeWord.charStart, 0, textLength);
        outWordEnd   = std::clamp(activeWord.charStart + activeWord.charLength, outWordStart, textLength);
        outSegments.clear();
        outTotalWidth = 0.0;

        if (outWordEnd <= outWordStart)
            return;

        const int lineCount = layout.lineCount();
        for (int lineIndex = 0; lineIndex < lineCount; ++lineIndex) {
            const QTextLine line      = layout.lineAt(lineIndex);
            const int       lineStart = line.textStart();
            const int       lineEnd   = lineStart + line.textLength();
            if (lineEnd <= outWordStart || lineStart >= outWordEnd)
                continue;
            const int   segmentStart = std::max(outWordStart, lineStart);
            const int   segmentEnd   = std::min(outWordEnd, lineEnd);
            const qreal leftCursor   = line.cursorToX(segmentStart);
            const qreal rightCursor  = line.cursorToX(segmentEnd);
            const qreal segmentWidth = std::abs(rightCursor - leftCursor);
            if (segmentWidth <= 0.0)
                continue;
            outSegments.append({
                .lineIndex = lineIndex,
                .leftX     = std::min(leftCursor, rightCursor),
                .width     = segmentWidth,
                .topY      = line.y(),
                .height    = line.height(),
            });
            outTotalWidth += segmentWidth;
        }
    }

    inline void populateActiveWordNodes(QTextLayout& layout, qreal yOffset, int wordStart, qreal totalWidth, double progress, const QList<SLineSegment>& segments,
                                        const QColor& effectiveActive, bool raised, const QColor& styleColor, QSGTextNode* completedLinesNode, const QList<QSGClipNode*>& clipNodes,
                                        const QList<QSGTextNode*>& clippedTextNodes) {
        configureTextNode(completedLinesNode, effectiveActive, raised, styleColor);
        const int lineCount = layout.lineCount();
        for (int lineIdx = 0; lineIdx < lineCount; ++lineIdx) {
            const QTextLine line    = layout.lineAt(lineIdx);
            const int       lineEnd = line.textStart() + line.textLength();
            if (lineEnd <= wordStart)
                completedLinesNode->addTextLayout(QPointF(0.0, yOffset), &layout, -1, -1, lineIdx, 1);
        }

        qreal remainingFill = totalWidth * static_cast<qreal>(progress);
        for (qsizetype segIdx = 0; segIdx < segments.size(); ++segIdx) {
            const SLineSegment& segment = segments.at(segIdx);
            if (segIdx > 0 && remainingFill <= 0.0)
                break;
            const qreal clipWidth = std::clamp(remainingFill, 0.0, segment.width);
            const qreal fillRight = segment.leftX + clipWidth;
            if (fillRight > 0.0) {
                const QRectF clipRect(0.0, yOffset + segment.topY, fillRight, segment.height);
                QSGClipNode* clipNode = clipNodes.at(segIdx);
                QSGTextNode* textNode = clippedTextNodes.at(segIdx);
                clipNode->setClipRect(clipRect);
                QSGGeometry::updateRectGeometry(clipNode->geometry(), clipRect);
                clipNode->markDirty(QSGNode::DirtyGeometry);

                configureTextNode(textNode, effectiveActive, raised, styleColor);
                textNode->addTextLayout(QPointF(0.0, yOffset), &layout, -1, -1, segment.lineIndex, 1);
            }
            remainingFill -= segment.width;
        }
    }

} // namespace vast::lyric_render
