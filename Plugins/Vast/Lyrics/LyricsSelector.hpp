#pragma once

#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qstring.h>

#include <optional>

#include "LrcParser.hpp"

namespace vast {

    struct SSelectedLyrics {
        QJsonObject       rawObject;
        LrcParser::Result parsed;
    };

    /// Pure LRCLIB payload parsing and multi-candidate search selection.
    /// Prefers word-synced payloads over line-synced over plain text.
    class LyricsSelector {
      public:
        static constexpr double CLOSE_DURATION_DIFF_SECS      = 3.0;
        static constexpr double MAX_SYNCED_DURATION_DIFF_SECS = 10.0;

        /// Parses a single LRCLIB JSON record, strictly preferring word-synced
        /// lyrics (`lyricsfile` words or Enhanced LRC `<mm:ss.xx>` tags) before
        /// falling back to line-synced lyrics and finally plain lyrics.
        [[nodiscard]] static std::optional<LrcParser::Result> parsePayload(const QJsonObject& payload, double durationSecs);

        /// Ranks an LRCLIB `/api/search` JSON array and selects the best matching
        /// record for `(title, artist, durationSecs)`, preferring word-synced
        /// entries among close-duration matches of the same track.
        [[nodiscard]] static std::optional<SSelectedLyrics> selectBestCandidate(const QJsonArray& candidates, const QString& title, const QString& artist, double durationSecs);
    };

} // namespace vast
