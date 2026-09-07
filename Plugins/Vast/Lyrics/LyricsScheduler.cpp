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
        mWordTimer.setSingleShot(true);
        mWordTimer.setTimerType(Qt::PreciseTimer);
        connect(&mWordTimer, &QTimer::timeout, this, &LyricsScheduler::onWordTimer);
    }

    qint64 LyricsScheduler::currentPositionMs() const {
        if (!mPlaying)
            return mAnchorMs;
        const qint64 wallNow       = QDateTime::currentMSecsSinceEpoch();
        const auto   elapsed       = static_cast<double>(wallNow - mAnchorWall);
        const auto   scaledElapsed = static_cast<qint64>(std::llround(elapsed * mRate));
        return mAnchorMs + scaledElapsed + mOffsetMs;
    }

    void LyricsScheduler::setWordLines(const QVariantList& wordLines) {
        mWordLines = wordLines;
        rebuildBoundaries();
        reschedule();
    }

    void LyricsScheduler::setPlayback(double positionSecs, double rate, bool playing) {
        mAnchorMs   = static_cast<qint64>(positionSecs * 1000.0);
        mAnchorWall = QDateTime::currentMSecsSinceEpoch();
        mRate       = rate;
        mPlaying    = playing;
        reschedule();
    }

    void LyricsScheduler::setOffsetMs(int offset) {
        if (mOffsetMs == offset)
            return;
        mOffsetMs = offset;
        reschedule();
    }

    void LyricsScheduler::reschedule() {
        mWordTimer.stop();

        if (mBoundaries.isEmpty())
            return;

        const qint64 posMs = currentPositionMs();
        seekTo(posMs);

        if (mPlaying)
            scheduleNext();
    }

    void LyricsScheduler::reset() {
        mWordTimer.stop();
        mBoundaries.clear();
        mWordLines.clear();
        mBoundaryPos     = 0;
        mCurLine         = -1;
        mCurWord         = -1;
        mCurWordDuration = 0;
        Q_EMIT currentIndexChanged();
    }

    void LyricsScheduler::seekTo(qint64 posMs) {
        auto            it    = std::ranges::upper_bound(mBoundaries, posMs, {}, &WordBoundary::timeMs);
        const qsizetype found = (it != mBoundaries.begin()) ? std::distance(mBoundaries.begin(), std::prev(it)) : -1;

        const int       newLine = (found >= 0) ? mBoundaries.at(found).lineIndex : -1;
        const int       newWord = (found >= 0) ? mBoundaries.at(found).wordIndex : -1;

        bool            durationChanged = false;
        qint64          newDuration     = 0;
        if (newLine >= 0 && newWord >= 0 && newLine < mWordLines.size()) {
            const auto wl    = mWordLines.at(newLine).toMap();
            const auto words = wl[QStringLiteral("words")].toList();
            if (newWord < words.size())
                newDuration = words.at(newWord).toMap()[QStringLiteral("duration")].toLongLong();
        }

        if (newDuration != mCurWordDuration) {
            mCurWordDuration = newDuration;
            durationChanged  = true;
        }

        if (newLine != mCurLine || newWord != mCurWord) {
            mCurLine = newLine;
            mCurWord = newWord;
            Q_EMIT currentIndexChanged();
        }

        if (durationChanged)
            Q_EMIT currentWordDurationChanged();

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

        mWordTimer.start(static_cast<int>(delayMs));
    }

    void LyricsScheduler::onWordTimer() {
        if (!mPlaying)
            return;

        const qint64 nowMs = currentPositionMs();

        bool         changedIndex = false;
        while (mBoundaryPos < mBoundaries.size() && mBoundaries.at(mBoundaryPos).timeMs <= nowMs) {
            const auto b = mBoundaries.at(mBoundaryPos);
            mCurLine     = b.lineIndex;
            mCurWord     = b.wordIndex;
            changedIndex = true;
            ++mBoundaryPos;
        }

        if (changedIndex) {
            Q_EMIT   currentIndexChanged();

            qint64 newDuration = 0;
            if (mCurLine >= 0 && mCurWord >= 0 && mCurLine < mWordLines.size()) {
                const auto wl    = mWordLines.at(mCurLine).toMap();
                const auto words = wl[QStringLiteral("words")].toList();
                if (mCurWord < words.size())
                    newDuration = words.at(mCurWord).toMap()[QStringLiteral("duration")].toLongLong();
            }
            if (newDuration != mCurWordDuration) {
                mCurWordDuration = newDuration;
                Q_EMIT currentWordDurationChanged();
            }
        }

        scheduleNext();
    }

    void LyricsScheduler::rebuildBoundaries() {
        mBoundaries.clear();
        for (int li = 0; li < mWordLines.size(); ++li) {
            const auto& wlEntry = mWordLines.at(li).toMap();
            const auto  words   = wlEntry[QStringLiteral("words")].toList();
            for (int wi = 0; wi < words.size(); ++wi) {
                const auto   word = words.at(wi).toMap();
                const qint64 t    = word[QStringLiteral("time")].toLongLong();
                if (t < 0)
                    continue;
                mBoundaries.append({.timeMs = t, .lineIndex = li, .wordIndex = wi});
            }
        }
        std::ranges::stable_sort(mBoundaries, {}, &WordBoundary::timeMs);
    }
}
