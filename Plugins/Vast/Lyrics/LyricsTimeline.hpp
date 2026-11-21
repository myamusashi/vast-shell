#pragma once

#include <qstring.h>
#include <qtypes.h>
#include <qvariant.h>

#include <vector>

namespace vast {

    /// Maps a lyric line's text and parsed word timings onto ordered word
    /// intervals [startMs, endMs] and tracks the active word index across
    /// sequential playback, pauses, and arbitrary forward/backward seeks.
    class LyricsTimeline {
      public:
        struct WordTiming {
            int    charStart{0};
            int    charLength{0};
            qint64 startMs{0};
            qint64 endMs{0};
        };

        void                            rebuild(const QString& text, const QVariantList& words);
        void                            clear();

        [[nodiscard]] bool              isEmpty() const noexcept;
        [[nodiscard]] qsizetype         wordCount() const noexcept;
        [[nodiscard]] const WordTiming& wordAt(qsizetype index) const;

        /// Updates the tracked active word index for `positionMs`.
        /// Returns true when the visible highlight state may have changed.
        bool                    updatePosition(qint64 positionMs) noexcept;

        [[nodiscard]] qsizetype activeWordIndex() const noexcept;
        [[nodiscard]] double    activeWordProgress(qint64 positionMs) const noexcept;
        [[nodiscard]] double    wordProgressAt(qsizetype index, qint64 positionMs) const noexcept;

      private:
        std::vector<WordTiming> mWords;
        qsizetype               mActiveWordIndex{-1};
        qint64                  mLastPositionMs{0};
        bool                    mHasLastPosition{false};
    };
} // namespace vast
