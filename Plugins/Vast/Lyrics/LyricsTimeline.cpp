#include "LyricsTimeline.hpp"

#include <qminmax.h>
#include <qstring.h>
#include <qtypes.h>
#include <qvariant.h>

#include <algorithm>
#include <cstddef>
#include <iterator>
#include <vector>

namespace vast {

    void LyricsTimeline::clear() {
        mWords.clear();
        mActiveWordIndex = -1;
        mLastPositionMs  = 0;
        mHasLastPosition = false;
    }

    bool LyricsTimeline::isEmpty() const noexcept {
        return mWords.empty();
    }

    qsizetype LyricsTimeline::wordCount() const noexcept {
        return static_cast<qsizetype>(mWords.size());
    }

    const LyricsTimeline::WordTiming& LyricsTimeline::wordAt(qsizetype index) const {
        return mWords.at(static_cast<std::size_t>(index));
    }

    qsizetype LyricsTimeline::activeWordIndex() const noexcept {
        return mActiveWordIndex;
    }

    void LyricsTimeline::rebuild(const QString& text, const QVariantList& words) {
        clear();
        if (text.isEmpty() || words.isEmpty())
            return;

        mWords.reserve(static_cast<std::size_t>(words.size()));
        qsizetype fallbackSearchPos = 0;

        for (const QVariant& entry : words) {
            const QVariantMap w  = entry.toMap();
            const qint64 startMs = w.contains(QStringLiteral("startTime")) ? w.value(QStringLiteral("startTime")).toLongLong() : w.value(QStringLiteral("time"), -1).toLongLong();
            if (startMs < 0)
                continue;

            const qint64 rawEndMs = w.contains(QStringLiteral("endTime")) ? w.value(QStringLiteral("endTime")).toLongLong() :
                                                                            startMs + qMax<qint64>(0, w.value(QStringLiteral("duration"), 0).toLongLong());

            qsizetype    charStart  = -1;
            qsizetype    charLength = 0;
            if (w.contains(QStringLiteral("charStart")) && w.contains(QStringLiteral("charLength"))) {
                charStart  = w.value(QStringLiteral("charStart")).toLongLong();
                charLength = w.value(QStringLiteral("charLength")).toLongLong();
            } else {
                const QString wText = w.value(QStringLiteral("text")).toString();
                if (!wText.isEmpty()) {
                    const qsizetype found = text.indexOf(wText, fallbackSearchPos);
                    if (found >= 0) {
                        charStart         = found;
                        charLength        = wText.length();
                        fallbackSearchPos = charStart + charLength;
                    }
                }
            }

            if (charStart < 0 || charLength <= 0)
                continue;

            mWords.push_back({
                .charStart  = static_cast<int>(charStart),
                .charLength = static_cast<int>(charLength),
                .startMs    = startMs,
                .endMs      = qMax(startMs, rawEndMs),
            });
        }

        if (mWords.empty())
            return;

        std::ranges::stable_sort(mWords, {}, &WordTiming::startMs);
        for (std::size_t i = 0; i + 1 < mWords.size(); ++i) {
            mWords[i].endMs = std::clamp(mWords[i].endMs, mWords[i].startMs, mWords[i + 1].startMs);
        }
    }

    bool LyricsTimeline::updatePosition(qint64 positionMs) noexcept {
        if (mWords.empty()) {
            mActiveWordIndex = -1;
            return false;
        }

        const qsizetype prevIdx     = mActiveWordIndex;
        const bool      hadPrevPos  = mHasLastPosition;
        const qint64    prevPosMs   = mLastPositionMs;
        const auto      wordCountSz = mWords.size();

        if (positionMs < mWords[0].startMs) {
            mActiveWordIndex = -1;
        } else if (mActiveWordIndex < 0) {
            auto it          = std::ranges::upper_bound(mWords, positionMs, {}, &WordTiming::startMs);
            mActiveWordIndex = (it == mWords.begin()) ? -1 : static_cast<qsizetype>(std::distance(mWords.begin(), std::prev(it)));
        } else {
            auto idx = static_cast<std::size_t>(mActiveWordIndex);
            if (positionMs < mWords[idx].startMs) {
                auto begin       = mWords.begin();
                auto end         = mWords.begin() + mActiveWordIndex;
                auto it          = std::upper_bound(begin, end, positionMs, [](qint64 pos, const WordTiming& w) { return pos < w.startMs; });
                mActiveWordIndex = (it == begin) ? -1 : static_cast<qsizetype>(std::distance(begin, std::prev(it)));
            } else {
                while (idx + 1 < wordCountSz && positionMs >= mWords[idx + 1].startMs)
                    ++idx;
                mActiveWordIndex = static_cast<qsizetype>(idx);
            }
        }

        mLastPositionMs  = positionMs;
        mHasLastPosition = true;

        if (!hadPrevPos || prevIdx != mActiveWordIndex)
            return true;

        if (mActiveWordIndex < 0)
            return false;

        const auto& w = mWords[static_cast<std::size_t>(mActiveWordIndex)];
        if (prevPosMs >= w.endMs && positionMs >= w.endMs)
            return false;

        return prevPosMs != positionMs;
    }

    double LyricsTimeline::activeWordProgress(qint64 positionMs) const noexcept {
        return wordProgressAt(mActiveWordIndex, positionMs);
    }

    double LyricsTimeline::wordProgressAt(qsizetype index, qint64 positionMs) const noexcept {
        if (index < 0 || index >= wordCount())
            return 0.0;
        const auto& w = mWords[static_cast<std::size_t>(index)];
        if (positionMs < w.startMs)
            return 0.0;
        const qint64 durationMs = w.endMs - w.startMs;
        if (durationMs <= 0 || positionMs >= w.endMs)
            return 1.0;
        return static_cast<double>(positionMs - w.startMs) / static_cast<double>(durationMs);
    }
} // namespace vast
