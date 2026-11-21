#pragma once

#include <qcolor.h>
#include <qelapsedtimer.h>
#include <qfont.h>
#include <qlist.h>
#include <qnamespace.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qstring.h>
#include <qtextlayout.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include <memory>
#include <vector>

#include "LyricRenderUtils.hpp"
#include "LyricsTimeline.hpp"

class QSGNode;
class QWheelEvent;

// GPU-accelerated lyrics view rendered natively on the Qt Quick Scene Graph
// using QSGTextNode, QSGTransformNode, QSGOpacityNode, and QSGClipNode.
// Ownership: QML-parented when instantiated declaratively in QML; internal
// QSGNode subtrees are owned by the Qt Quick Scene Graph.
class LyricsCanvas : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantList lines READ lines WRITE setLines NOTIFY linesChanged)
    Q_PROPERTY(int currentLineIndex READ currentLineIndex WRITE setCurrentLineIndex NOTIFY currentLineIndexChanged)
    Q_PROPERTY(qint64 positionMs READ positionMs WRITE setPositionMs NOTIFY positionMsChanged)
    Q_PROPERTY(bool synced READ synced WRITE setSynced NOTIFY syncedChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(QColor activeColor READ activeColor WRITE setActiveColor NOTIFY activeColorChanged)
    Q_PROPERTY(QColor inactiveColor READ inactiveColor WRITE setInactiveColor NOTIFY inactiveColorChanged)
    Q_PROPERTY(QColor styleColor READ styleColor WRITE setStyleColor NOTIFY styleColorChanged)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(qreal activeFontSize READ activeFontSize WRITE setActiveFontSize NOTIFY activeFontSizeChanged)
    Q_PROPERTY(qreal inactiveFontSize READ inactiveFontSize WRITE setInactiveFontSize NOTIFY inactiveFontSizeChanged)
    Q_PROPERTY(int horizontalAlignment READ horizontalAlignment WRITE setHorizontalAlignment NOTIFY horizontalAlignmentChanged)
    Q_PROPERTY(qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(bool raised READ raised WRITE setRaised NOTIFY raisedChanged)

  public:
    explicit LyricsCanvas(QQuickItem* parent = nullptr);

    [[nodiscard]] QVariantList lines() const;
    void                       setLines(const QVariantList& lines);

    [[nodiscard]] int          currentLineIndex() const noexcept;
    void                       setCurrentLineIndex(int index);

    [[nodiscard]] qint64       positionMs() const noexcept;
    void                       setPositionMs(qint64 positionMs);

    [[nodiscard]] bool         synced() const noexcept;
    void                       setSynced(bool synced);

    [[nodiscard]] bool         active() const noexcept;
    void                       setActive(bool active);

    [[nodiscard]] QColor       activeColor() const noexcept;
    void                       setActiveColor(const QColor& color);

    [[nodiscard]] QColor       inactiveColor() const noexcept;
    void                       setInactiveColor(const QColor& color);

    [[nodiscard]] QColor       styleColor() const noexcept;
    void                       setStyleColor(const QColor& color);

    [[nodiscard]] QFont        font() const;
    void                       setFont(const QFont& font);

    [[nodiscard]] qreal        activeFontSize() const noexcept;
    void                       setActiveFontSize(qreal size);

    [[nodiscard]] qreal        inactiveFontSize() const noexcept;
    void                       setInactiveFontSize(qreal size);

    [[nodiscard]] int          horizontalAlignment() const noexcept;
    void                       setHorizontalAlignment(int alignment);

    [[nodiscard]] qreal        spacing() const noexcept;
    void                       setSpacing(qreal spacing);

    [[nodiscard]] bool         raised() const noexcept;
    void                       setRaised(bool raised);

  Q_SIGNALS:
    void linesChanged();
    void currentLineIndexChanged();
    void positionMsChanged();
    void syncedChanged();
    void activeChanged();
    void activeColorChanged();
    void inactiveColorChanged();
    void styleColorChanged();
    void fontChanged();
    void activeFontSizeChanged();
    void inactiveFontSizeChanged();
    void horizontalAlignmentChanged();
    void spacingChanged();
    void raisedChanged();

  protected:
    void     geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    void     wheelEvent(QWheelEvent* event) override;
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData) override;

  private:
    struct SLyricEntry {
        QString                                 text;
        QString                                 translation;
        vast::LyricsTimeline                    timeline;
        QTextLayout                             textLayout;
        QTextLayout                             translationLayout;
        qreal                                   textHeight{0.0};
        qreal                                   translationHeight{0.0};
        qreal                                   topY{0.0};
        qreal                                   totalHeight{0.0};
        qreal                                   highlightMix{0.0};
        qreal                                   scale{0.9};
        qreal                                   opacity{0.45};
        qsizetype                               cachedWordIndex{-1};
        int                                     cachedWordStart{0};
        int                                     cachedWordEnd{0};
        qreal                                   cachedTotalWidth{0.0};
        QList<vast::lyric_render::SLineSegment> cachedSegments;
    };

    void                                      rebuildEntries();
    void                                      relayoutEntries();
    void                                      updateTargetScroll(bool animate);
    void                                      startAnimationLoop();
    void                                      onAnimationTick();
    static void                               ensureWordCache(SLyricEntry& entry, qsizetype activeWordIndex);

    QVariantList                              mLines;
    int                                       mCurrentLineIndex{-1};
    qint64                                    mPositionMs{0};
    bool                                      mSynced{true};
    bool                                      mActive{true};
    QColor                                    mActiveColor{Qt::white};
    QColor                                    mInactiveColor{Qt::gray};
    QColor                                    mStyleColor{0, 0, 0, 128};
    QFont                                     mFont;
    qreal                                     mActiveFontSize{18.0};
    qreal                                     mInactiveFontSize{14.0};
    int                                       mHorizontalAlignment{Qt::AlignLeft};
    qreal                                     mSpacing{16.0};
    bool                                      mRaised{true};

    std::vector<std::unique_ptr<SLyricEntry>> mEntries;
    qreal                                     mContentHeight{0.0};
    qreal                                     mScrollY{0.0};
    qreal                                     mTargetScrollY{0.0};
    bool                                      mLayoutDirty{true};
    bool                                      mScrollSnapPending{true};

    QTimer                                    mAnimTimer;
    QElapsedTimer                             mAnimClock;
};
