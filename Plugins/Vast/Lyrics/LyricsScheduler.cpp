#include "LyricsScheduler.hpp"

#include <qcontainerfwd.h>
#include <qelapsedtimer.h>
#include <qnamespace.h>
#include <qnumeric.h>
#include <qobject.h>
#include <qtmetamacros.h>
#include <qtypes.h>

#include <algorithm>
#include <cmath>
#include <iterator>

namespace {
    // Re-arm long instrumental waits in chunks so gaps over 60 s never stall scheduling.
    constexpr qint64 MAX_TIMER_CHUNK_MS = 60'000;
} // namespace

namespace vast {

    LyricsScheduler::LyricsScheduler(QObject* parent) : QObject(parent) {
        mLineTimer.setSingleShot(true);
        mLineTimer.setTimerType(Qt::PreciseTimer);
        connect(&mLineTimer, &QTimer::timeout, this, &LyricsScheduler::onLineTimer);
    }

    qint64 LyricsScheduler::currentPositionMs() const {
        // The offset applies while paused too, so both paths resolve alike.
        if (!mPlaying || !mAnchorClock.isValid())
            return mAnchorMs + mOffsetMs;
        const auto elapsedMs     = static_cast<double>(mAnchorClock.nsecsElapsed()) * 1e-6;
        const auto scaledElapsed = static_cast<qint64>(std::llround(elapsedMs * mRate));
        return mAnchorMs + scaledElapsed + mOffsetMs;
    }

    void LyricsScheduler::setWordLines(const QVariantList& wordLines) {
        rebuildBoundaries(wordLines);
        reschedule();
    }

    void LyricsScheduler::setPlayback(double positionSecs, double rate, bool playing) {
        const double effectiveRate      = (rate > 0.0 && std::isfinite(rate)) ? rate : 1.0;
        const bool   playingChangedFlag = (mPlaying != playing);
        const bool   rateChangedFlag    = !qFuzzyCompare(1.0 + mRate, 1.0 + effectiveRate);

        mAnchorMs = static_cast<qint64>(std::llround(positionSecs * 1000.0));
        mAnchorClock.start();
        mRate    = effectiveRate;
        mPlaying = playing;

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
                scheduleNext(posMs);
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
        mAnchorClock.invalidate();
        mPlaying = false;
        mRate    = 1.0;
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

    void LyricsScheduler::scheduleNext(qint64 nowMs) {
        if (mBoundaryPos >= mBoundaries.size())
            return;

        const qint64 mediaDelayMs = mBoundaries.at(mBoundaryPos).timeMs - nowMs;
        const qint64 wallDelayMs  = std::max<qint64>(1, static_cast<qint64>(std::ceil(static_cast<double>(mediaDelayMs) / mRate)));
        const int    timerDelayMs = static_cast<int>(std::min<qint64>(wallDelayMs, MAX_TIMER_CHUNK_MS));

        mLineTimer.start(timerDelayMs);
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

        scheduleNext(nowMs);
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
