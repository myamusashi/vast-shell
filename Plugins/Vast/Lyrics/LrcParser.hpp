#pragma once

#include <qlist.h>
#include <qstring.h>
#include <qvariant.h>
#include <qtypes.h>

namespace vast {

    /// Parses LRC-format (line- and optionally word-synced) or plain-text
    /// lyrics into the QVariantList shape LyricsProvider exposes to QML.
    /// Pure — no network, no disk, no playback state.
    class LrcParser {
      public:
        static constexpr qint64 MAX_LAST_WORD_DURATION_MS = 5000;
        static constexpr qint64 LAST_LINE_TAIL_MS         = 5000;

        // Caps sparse lines so a few words do not stretch across long instrumental tails.
        static constexpr qint64 FALLBACK_MAX_MS_PER_WORD = 1200;
        // Paces multi-syllable words proportionally up to 600 ms per syllable.
        static constexpr qint64 FALLBACK_MAX_MS_PER_SYLLABLE = 600;
        // Leaves a 5% gap before the next line so highlights settle before line transitions.
        static constexpr double FALLBACK_LINE_FILL_RATIO = 0.95;
        // Adds a half-syllable pause after mid-line punctuation (comma, semicolon, colon).
        static constexpr double FALLBACK_COMMA_PAUSE_WEIGHT = 0.5;
        // Adds a full-syllable pause after sentence-ending punctuation before the next word.
        static constexpr double FALLBACK_SENTENCE_PAUSE_WEIGHT = 1.0;

        struct Result {
            QVariantList lines;
            QVariantList wordLines;
            bool         synced{false};
            bool         wordSynced{false};
        };

        /// Parses LRC-format text (with [mm:ss.xx] line tags and optional
        /// <mm:ss.xx> word tags). totalDurationSecs is used as a fallback
        /// end-time for the final line if it can't be inferred from spacing.
        [[nodiscard]] static Result parseLrc(const QString& lrc, double totalDurationSecs);

        /// Parses an LRCLIB Lyricsfile (YAML) payload carrying per-word start
        /// times. Returns an empty, unsynced Result when the payload is invalid
        /// or has no usable lines so the caller can fall back to syncedLyrics.
        [[nodiscard]] static Result parseLyricsfile(const QString& yamlText, double totalDurationSecs);

        /// Parses plain (unsynced) lyrics — one line per row, no timestamps.
        [[nodiscard]] static Result parsePlain(const QString& plain);

      private:
        [[nodiscard]] static qint64       parseTimestamp(const QString& mm, const QString& ss, const QString& frac);
        [[nodiscard]] static QVariantList interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs);
    };
}
