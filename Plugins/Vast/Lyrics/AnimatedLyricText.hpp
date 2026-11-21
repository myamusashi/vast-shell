#pragma once

#include <qcolor.h>
#include <qfont.h>
#include <qlist.h>
#include <qnamespace.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qrect.h>
#include <qstring.h>
#include <qtextlayout.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include "LyricRenderUtils.hpp"
#include "LyricsTimeline.hpp"

class QSGNode;

class AnimatedLyricText : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QVariantList words READ words WRITE setWords NOTIFY wordsChanged)
    Q_PROPERTY(qint64 positionMs READ positionMs WRITE setPositionMs NOTIFY positionMsChanged)
    Q_PROPERTY(bool synced READ synced WRITE setSynced NOTIFY syncedChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(qreal highlightMix READ highlightMix WRITE setHighlightMix NOTIFY highlightMixChanged)
    Q_PROPERTY(QColor activeColor READ activeColor WRITE setActiveColor NOTIFY activeColorChanged)
    Q_PROPERTY(QColor inactiveColor READ inactiveColor WRITE setInactiveColor NOTIFY inactiveColorChanged)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(int horizontalAlignment READ horizontalAlignment WRITE setHorizontalAlignment NOTIFY horizontalAlignmentChanged)
    Q_PROPERTY(int wrapMode READ wrapMode WRITE setWrapMode NOTIFY wrapModeChanged)
    Q_PROPERTY(bool raised READ raised WRITE setRaised NOTIFY raisedChanged)
    Q_PROPERTY(QColor styleColor READ styleColor WRITE setStyleColor NOTIFY styleColorChanged)

  public:
    explicit AnimatedLyricText(QQuickItem* parent = nullptr);

    [[nodiscard]] QString      text() const;
    void                       setText(const QString& text);

    [[nodiscard]] QVariantList words() const;
    void                       setWords(const QVariantList& words);

    [[nodiscard]] qint64       positionMs() const noexcept;
    void                       setPositionMs(qint64 positionMs);

    [[nodiscard]] bool         synced() const noexcept;
    void                       setSynced(bool synced);

    [[nodiscard]] bool         active() const noexcept;
    void                       setActive(bool active);

    [[nodiscard]] qreal        highlightMix() const noexcept;
    void                       setHighlightMix(qreal highlightMix);

    [[nodiscard]] QColor       activeColor() const noexcept;
    void                       setActiveColor(const QColor& color);

    [[nodiscard]] QColor       inactiveColor() const noexcept;
    void                       setInactiveColor(const QColor& color);

    [[nodiscard]] QFont        font() const;
    void                       setFont(const QFont& font);

    [[nodiscard]] int          horizontalAlignment() const noexcept;
    void                       setHorizontalAlignment(int alignment);

    [[nodiscard]] int          wrapMode() const noexcept;
    void                       setWrapMode(int wrapMode);

    [[nodiscard]] bool         raised() const noexcept;
    void                       setRaised(bool raised);

    [[nodiscard]] QColor       styleColor() const noexcept;
    void                       setStyleColor(const QColor& color);

  Q_SIGNALS:
    void textChanged();
    void wordsChanged();
    void positionMsChanged();
    void syncedChanged();
    void activeChanged();
    void highlightMixChanged();
    void activeColorChanged();
    void inactiveColorChanged();
    void fontChanged();
    void horizontalAlignmentChanged();
    void wrapModeChanged();
    void raisedChanged();
    void styleColorChanged();

  protected:
    void     geometryChange(const QRectF& newGeometry, const QRectF& oldGeometry) override;
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* updatePaintNodeData) override;

  private:
    void                                    relayout();
    void                                    rebuildTimeline();
    void                                    invalidateActiveWordCache() noexcept;
    void                                    ensureActiveWordCache(qsizetype activeWordIndex, int textLength);

    QString                                 mText;
    QVariantList                            mWords;
    qint64                                  mPositionMs{0};
    bool                                    mSynced{true};
    bool                                    mActive{false};
    qreal                                   mHighlightMix{0.0};
    QColor                                  mActiveColor{Qt::white};
    QColor                                  mInactiveColor{Qt::gray};
    QFont                                   mFont;
    int                                     mHorizontalAlignment{Qt::AlignLeft};
    int                                     mWrapMode{4}; // Text.Wrap (WrapAtWordBoundaryOrAnywhere)
    bool                                    mRaised{false};
    QColor                                  mStyleColor{Qt::black};

    QTextLayout                             mLayout;
    qreal                                   mLayoutHeight{0.0};
    vast::LyricsTimeline                    mTimeline;

    QList<vast::lyric_render::SLineSegment> mCachedSegments;
    qreal                                   mCachedTotalWidth{0.0};
    qsizetype                               mCachedActiveWordIndex{-1};
    int                                     mCachedWordStart{0};
    int                                     mCachedWordEnd{0};
    bool                                    mSegmentCacheValid{false};
};
