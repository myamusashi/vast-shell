#include "LyricsScheduler.hpp"

#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qtmetamacros.h>
#include <qtypes.h>

#include <algorithm>
#include <cmath>
#include <iterator>

namespace vast {

    LyricsScheduler::LyricsScheduler(QObject* parent) : QObject(parent) {
        mLineTimer.setSingleShot(true);
        mLineTimer.setTimerType(Qt::PreciseTimer);
        connect(&mLineTimer, &QTimer::timeout, this, &LyricsScheduler::onLineTimer);
    }

    qint64 LyricsScheduler::currentPositionMs() const {
        // The offset applies while paused too, so both paths resolve alike.
        if (!mPlaying)
            return mAnchorMs + mOffsetMs;
        const qint64 wallNow       = QDateTime::currentMSecsSinceEpoch();
        const auto   elapsed       = static_cast<double>(wallNow - mAnchorWall);
        const auto   scaledElapsed = static_cast<qint64>(std::llround(elapsed * mRate));
        return mAnchorMs + scaledElapsed + mOffsetMs;
    }

    void LyricsScheduler::setWordLines(const QVariantList& wordLines) {
        rebuildBoundaries(wordLines);
        reschedule();
    }

    void LyricsScheduler::setPlayback(double positionSecs, double rate, bool playing) {
        const bool playingChangedFlag = (mPlaying != playing);
        const bool rateChangedFlag    = !qFuzzyCompare(1.0 + mRate, 1.0 + rate);

        mAnchorMs   = static_cast<qint64>(positionSecs * 1000.0);
        mAnchorWall = QDateTime::currentMSecsSinceEpoch();
        mRate       = rate;
        mPlaying    = playing;

        if (playingChangedFlag)
            Q_EMIT playingChanged();
        if (rateChangedFlag)
            Q_EMIT rateChanged();

        reschedule();
    }

    void LyricsScheduler::setOffsetMs(int offset) {
        if (mOffsetMs == offset)
            return;
        mOffsetMs = offset;
        reschedule();
    }

    void LyricsScheduler::reschedule() {
        mLineTimer.stop();

        if (!mBoundaries.isEmpty()) {
            const qint64 posMs = currentPositionMs();
            seekTo(posMs);

            if (mPlaying)
                scheduleNext();
        }

        Q_EMIT playbackSynced();
    }

    void LyricsScheduler::reset() {
        mLineTimer.stop();
        mBoundaries.clear();
        mBoundaryPos                  = 0;
        const bool lineChanged        = (mCurLine != -1);
        const bool playingChangedFlag = mPlaying;
        const bool rateChangedFlag    = !qFuzzyCompare(1.0 + mRate, 2.0);
        mCurLine                      = -1;
        mAnchorMs                     = 0;
        mAnchorWall                   = 0;
        mPlaying                      = false;
        mRate                         = 1.0;
        if (lineChanged)
            Q_EMIT currentLineIndexChanged();
        if (playingChangedFlag)
            Q_EMIT playingChanged();
        if (rateChangedFlag)
            Q_EMIT rateChanged();
        Q_EMIT playbackSynced();
    }

    void LyricsScheduler::seekTo(qint64 posMs) {
        auto            it      = std::ranges::upper_bound(mBoundaries, posMs, {}, &LineBoundary::timeMs);
        const qsizetype found   = (it != mBoundaries.begin()) ? std::distance(mBoundaries.begin(), std::prev(it)) : -1;
        const int       newLine = (found >= 0) ? mBoundaries.at(found).lineIndex : -1;

        if (newLine != mCurLine) {
            mCurLine = newLine;
            Q_EMIT currentLineIndexChanged();
        }

        mBoundaryPos = found + 1;
    }

    void LyricsScheduler::scheduleNext() {
        const qint64 nowMs = currentPositionMs();

        while (mBoundaryPos < mBoundaries.size() && mBoundaries.at(mBoundaryPos).timeMs <= nowMs) {
            ++mBoundaryPos;
        }

        if (mBoundaryPos >= mBoundaries.size())
            return;

        const qint64 delayMs = mBoundaries.at(mBoundaryPos).timeMs - nowMs;
        if (delayMs > 60'000)
            return;

        mLineTimer.start(static_cast<int>(delayMs));
    }

    void LyricsScheduler::onLineTimer() {
        if (!mPlaying)
            return;

        const qint64 nowMs       = currentPositionMs();
        bool         changedLine = false;

        while (mBoundaryPos < mBoundaries.size() && mBoundaries.at(mBoundaryPos).timeMs <= nowMs) {
            const auto boundary = mBoundaries.at(mBoundaryPos);
            if (boundary.lineIndex != mCurLine) {
                mCurLine    = boundary.lineIndex;
                changedLine = true;
            }
            ++mBoundaryPos;
        }

        if (changedLine)
            Q_EMIT currentLineIndexChanged();

        scheduleNext();
    }

    void LyricsScheduler::rebuildBoundaries(const QVariantList& wordLines) {
        mBoundaries.clear();
        for (int lineIndex = 0; lineIndex < wordLines.size(); ++lineIndex) {
            const auto   lineEntry = wordLines.at(lineIndex).toMap();
            const qint64 timeMs    = lineEntry.value(QStringLiteral("time"), -1).toLongLong();
            if (timeMs < 0)
                continue;
            mBoundaries.append({.timeMs = timeMs, .lineIndex = lineIndex});
        }
        std::ranges::stable_sort(mBoundaries, {}, &LineBoundary::timeMs);
    }
}
