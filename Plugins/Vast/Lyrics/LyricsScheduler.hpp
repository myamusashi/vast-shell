#pragma once

#include <qelapsedtimer.h>
#include <qlist.h>
#include <qobject.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

namespace vast {

    /// Owns dead-reckoning playback-position estimation and O(1) line-boundary
    /// scheduling for synced lyrics. Independent of network/parsing/caching —
    /// only needs the parsed line list (for line start times) and playback
    /// updates from the host (position/rate/playing + offset).
    class LyricsScheduler : public QObject {
        Q_OBJECT

      public:
        explicit LyricsScheduler(QObject* parent = nullptr);

        /// Rebuild the boundary list from a freshly-parsed wordLines list.
        /// Call this whenever lyrics change (new fetch, cache load, clear).
        void setWordLines(const QVariantList& wordLines);

        /// Call on every playback position/rate/state update from the host.
        void              setPlayback(double positionSecs, double rate, bool playing);

        void              setOffsetMs(int offset);
        [[nodiscard]] int offsetMs() const noexcept {
            return mOffsetMs;
        }

        void              reset();

        [[nodiscard]] int currentLineIndex() const noexcept {
            return mCurLine;
        }
        [[nodiscard]] bool playing() const noexcept {
            return mPlaying;
        }
        [[nodiscard]] double rate() const noexcept {
            return mRate;
        }
        [[nodiscard]] qint64 currentPositionMs() const;

      Q_SIGNALS:
        void currentLineIndexChanged();
        void playingChanged();
        void rateChanged();
        void playbackSynced();

      private:
        struct LineBoundary {
            qint64 timeMs;
            int    lineIndex;
        };

        void                seekTo(qint64 posMs);
        void                scheduleNext(qint64 nowMs);
        void                onLineTimer();
        void                rebuildBoundaries(const QVariantList& wordLines);
        void                reschedule(); // stop timer, seek, schedule — shared by setPlayback/setOffsetMs

        QList<LineBoundary> mBoundaries;
        qsizetype           mBoundaryPos{0};

        int                 mCurLine{-1};
        int                 mOffsetMs{0};

        qint64              mAnchorMs{0};
        QElapsedTimer       mAnchorClock;
        double              mRate{1.0};
        bool                mPlaying{false};

        QTimer              mLineTimer;
    };
}