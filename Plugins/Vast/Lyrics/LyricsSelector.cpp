#include "LyricsSelector.hpp"

#include "LrcParser.hpp"

#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qjsonvalue.h>
#include <qstring.h>

#include <cmath>
#include <optional>
#include <tuple>
#include <utility>

namespace {

    [[nodiscard]] QString normalizeMeta(const QString& text) {
        return text.trimmed().simplified().toCaseFolded();
    }

    [[nodiscard]] int matchTier(const QString& candidate, const QString& requested) {
        if (requested.isEmpty())
            return 2;
        if (candidate.isEmpty())
            return 0;
        if (candidate == requested)
            return 2;
        if (candidate.contains(requested) || requested.contains(candidate))
            return 1;
        return 0;
    }

    struct SCandidateScore {
        int                titleMatch{0};
        int                artistMatch{0};
        bool               isSynced{false};
        bool               durationClose{false};
        bool               wordSynced{false};
        double             negDurationDiff{0.0};

        [[nodiscard]] auto asTuple() const noexcept {
            return std::tuple(titleMatch, artistMatch, isSynced, durationClose, wordSynced, negDurationDiff);
        }

        [[nodiscard]] bool operator>(const SCandidateScore& other) const noexcept {
            return asTuple() > other.asTuple();
        }
    };

} // namespace

namespace vast {

    std::optional<LrcParser::Result> LyricsSelector::parsePayload(const QJsonObject& payload, double durationSecs) {
        std::optional<LrcParser::Result> lyricsfileFallback;
        const QString                    lyricsfile = payload.value(QStringLiteral("lyricsfile")).toString();
        if (!lyricsfile.isEmpty()) {
            auto parsed = LrcParser::parseLyricsfile(lyricsfile, durationSecs);
            if (parsed.synced && parsed.wordSynced)
                return parsed;
            if (parsed.synced)
                lyricsfileFallback = std::move(parsed);
        }

        std::optional<LrcParser::Result> lrcFallback;
        const QString                    syncedLyrics = payload.value(QStringLiteral("syncedLyrics")).toString();
        if (!syncedLyrics.isEmpty()) {
            auto parsed = LrcParser::parseLrc(syncedLyrics, durationSecs);
            if (parsed.synced && parsed.wordSynced)
                return parsed;
            if (parsed.synced)
                lrcFallback = std::move(parsed);
        }

        if (lyricsfileFallback.has_value())
            return lyricsfileFallback;

        if (lrcFallback.has_value())
            return lrcFallback;

        const QString plainLyrics = payload.value(QStringLiteral("plainLyrics")).toString();
        if (!plainLyrics.isEmpty()) {
            auto parsed = LrcParser::parsePlain(plainLyrics);
            if (!parsed.lines.isEmpty())
                return parsed;
        }

        return std::nullopt;
    }

    std::optional<SSelectedLyrics> LyricsSelector::selectBestCandidate(const QJsonArray& candidates, const QString& title, const QString& artist, double durationSecs) {
        const QString                  normReqTitle  = normalizeMeta(title);
        const QString                  normReqArtist = normalizeMeta(artist);

        std::optional<SSelectedLyrics> bestSelection;
        SCandidateScore                bestScore;

        for (const auto& value : candidates) {
            if (!value.isObject())
                continue;

            const QJsonObject obj    = value.toObject();
            auto              parsed = parsePayload(obj, durationSecs);
            if (!parsed.has_value())
                continue;

            const double candDuration     = obj.value(QStringLiteral("duration")).toDouble(0.0);
            const bool   hasBothDurations = (durationSecs > 0.0 && candDuration > 0.0);
            const double durationDiff     = hasBothDurations ? std::abs(candDuration - durationSecs) : 0.0;

            if (hasBothDurations && parsed->synced && durationDiff > MAX_SYNCED_DURATION_DIFF_SECS)
                continue;

            const QString         normCandTitle  = normalizeMeta(obj.value(QStringLiteral("trackName")).toString());
            const QString         normCandArtist = normalizeMeta(obj.value(QStringLiteral("artistName")).toString());

            const SCandidateScore score{
                .titleMatch      = matchTier(normCandTitle, normReqTitle),
                .artistMatch     = matchTier(normCandArtist, normReqArtist),
                .isSynced        = parsed->synced,
                .durationClose   = !hasBothDurations || (durationDiff <= CLOSE_DURATION_DIFF_SECS),
                .wordSynced      = parsed->wordSynced,
                .negDurationDiff = -durationDiff,
            };

            if (!bestSelection.has_value() || score > bestScore) {
                bestScore     = score;
                bestSelection = SSelectedLyrics{
                    .rawObject = obj,
                    .parsed    = std::move(*parsed),
                };
            }
        }

        return bestSelection;
    }

} // namespace vast
