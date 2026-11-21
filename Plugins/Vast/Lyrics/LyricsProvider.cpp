#include "LyricsProvider.hpp"

#include "LrcParser.hpp"
#include "LyricsCache.hpp"
#include "LyricsScheduler.hpp"

#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qhashfunctions.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qnumeric.h>
#include <qobject.h>
#include <qtmetamacros.h>
#include <qurl.h>
#include <qurlquery.h>

#include <qvariant.h>

#include <optional>

namespace {
    constexpr qint64                                     CACHE_REFRESH_DAYS    = 7;
    constexpr qint64                                     CACHE_REFRESH_SECONDS = CACHE_REFRESH_DAYS * 24 * 60 * 60;

    [[nodiscard]] std::optional<vast::LrcParser::Result> parseLyricsPayload(const QJsonObject& payload, double durationSecs) {
        const QString lyricsfile = payload.value(QStringLiteral("lyricsfile")).toString();
        if (!lyricsfile.isEmpty()) {
            auto wordSyncedResult = vast::LrcParser::parseLyricsfile(lyricsfile, durationSecs);
            if (wordSyncedResult.synced)
                return wordSyncedResult;
        }

        const QString syncedLyrics = payload.value(QStringLiteral("syncedLyrics")).toString();
        if (!syncedLyrics.isEmpty())
            return vast::LrcParser::parseLrc(syncedLyrics, durationSecs);

        const QString plainLyrics = payload.value(QStringLiteral("plainLyrics")).toString();
        if (!plainLyrics.isEmpty())
            return vast::LrcParser::parsePlain(plainLyrics);

        return std::nullopt;
    }

    [[nodiscard]] QNetworkRequest buildLrclibRequest(const QString& title, const QString& artist, double durationSecs) {
        QUrl      url(QStringLiteral("https://lrclib.net/api/get"));
        QUrlQuery query;
        query.addQueryItem(QStringLiteral("track_name"), title);
        query.addQueryItem(QStringLiteral("artist_name"), artist);
        if (durationSecs > 0)
            query.addQueryItem(QStringLiteral("duration"), QString::number(qRound(durationSecs)));
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::UserAgentHeader, "Vast Shell/1.0");
        return request;
    }
} // namespace

LyricsProvider::LyricsProvider(QObject* parent) : QObject(parent), mNam(new QNetworkAccessManager(this)), mScheduler(new vast::LyricsScheduler(this)) {
    connect(mScheduler, &vast::LyricsScheduler::currentLineIndexChanged, this, &LyricsProvider::currentLineIndexChanged);
    connect(mScheduler, &vast::LyricsScheduler::playingChanged, this, &LyricsProvider::playingChanged);
    connect(mScheduler, &vast::LyricsScheduler::rateChanged, this, &LyricsProvider::rateChanged);
    connect(mScheduler, &vast::LyricsScheduler::playbackSynced, this, &LyricsProvider::playbackSynced);
}

qint64 LyricsProvider::currentPositionMs() const {
    return mScheduler->currentPositionMs();
}

void LyricsProvider::setPlayback(double positionSecs, double rate, bool playing) {
    mScheduler->setPlayback(positionSecs, rate, playing);
}

void LyricsProvider::setOffsetMs(int offset) {
    if (mScheduler->offsetMs() == offset)
        return;
    mScheduler->setOffsetMs(offset);
    Q_EMIT offsetMsChanged();
}

void LyricsProvider::fetch(const QString& title, const QString& artist, double durationSecs) {
    if (title.isEmpty() && artist.isEmpty()) {
        clear();
        return;
    }

    const QString key = vast::LyricsCache::key(title, artist, durationSecs);
    mActiveCacheKey   = key;
    if (tryLoadFromCache(title, artist, durationSecs, key))
        return;

    setState(State::Loading);

    auto* reply = mNam->get(buildLrclibRequest(title, artist, durationSecs));
    connect(reply, &QNetworkReply::finished, this, [this, reply, key, durationSecs] {
        reply->deleteLater();
        if (mActiveCacheKey != key)
            return;

        if (reply->error() != QNetworkReply::NoError) {
            setState(State::Error);
            return;
        }

        const QByteArray data = reply->readAll();
        const auto       json = QJsonDocument::fromJson(data).object();

        if (json.contains(QStringLiteral("code"))) {
            setState(State::NotFound);
            return;
        }

        if (const auto parsed = parseLyricsPayload(json, durationSecs)) {
            applyParseResult(*parsed);
            vast::LyricsCache::save(key, data, durationSecs);
            return;
        }

        setState(State::NotFound);
    });
}

void LyricsProvider::clear() {
    mActiveCacheKey.clear();
    mLines.clear();
    mWordLines.clear();
    mSynced     = false;
    mWordSynced = false;
    mScheduler->reset();
    setState(State::Idle);
    Q_EMIT lyricsChanged();
}

void LyricsProvider::setState(State s) {
    if (mState == s)
        return;
    mState = s;
    Q_EMIT stateChanged();
}

void LyricsProvider::applyParseResult(const vast::LrcParser::Result& result) {
    mLines      = result.lines;
    mWordLines  = result.wordLines;
    mSynced     = result.synced;
    mWordSynced = result.wordSynced;

    mScheduler->setWordLines(result.wordLines);

    setState(State::Ready);
    Q_EMIT lyricsChanged();
}

bool LyricsProvider::tryLoadFromCache(const QString& title, const QString& artist, double durationSecs, const QString& cacheKey) {
    const auto cached = vast::LyricsCache::load(cacheKey);
    if (!cached)
        return false;

    const auto json   = QJsonDocument::fromJson(cached->rawJson).object();
    const auto parsed = parseLyricsPayload(json, cached->durationSecs);
    if (!parsed)
        return false;

    applyParseResult(*parsed);

    const bool hasLyricsfile  = !json.value(QStringLiteral("lyricsfile")).toString().trimmed().isEmpty();
    const bool hasOtherLyrics = !json.value(QStringLiteral("syncedLyrics")).toString().isEmpty() || !json.value(QStringLiteral("plainLyrics")).toString().isEmpty();
    const bool isExpired      = cached->modifiedAt.isValid() && cached->modifiedAt.secsTo(QDateTime::currentDateTimeUtc()) >= CACHE_REFRESH_SECONDS;

    if (!hasLyricsfile && hasOtherLyrics && isExpired)
        refreshInBackground(title, artist, durationSecs, cacheKey);

    return true;
}

void LyricsProvider::refreshInBackground(const QString& title, const QString& artist, double durationSecs, const QString& cacheKey) {
    if (mRefreshingCacheKey == cacheKey)
        return;
    mRefreshingCacheKey = cacheKey;

    auto* reply = mNam->get(buildLrclibRequest(title, artist, durationSecs));
    connect(reply, &QNetworkReply::finished, this, [this, reply, cacheKey, durationSecs] {
        reply->deleteLater();
        if (mRefreshingCacheKey == cacheKey)
            mRefreshingCacheKey.clear();

        const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() != QNetworkReply::NoError || statusCode == 429)
            return;

        const QByteArray data = reply->readAll();
        const auto       json = QJsonDocument::fromJson(data).object();
        if (json.isEmpty() || json.contains(QStringLiteral("code")))
            return;

        const QString lyricsfile = json.value(QStringLiteral("lyricsfile")).toString();
        if (!lyricsfile.trimmed().isEmpty()) {
            const auto wordSyncedResult = vast::LrcParser::parseLyricsfile(lyricsfile, durationSecs);
            if (wordSyncedResult.synced) {
                vast::LyricsCache::save(cacheKey, data, durationSecs);
                if (mActiveCacheKey == cacheKey)
                    applyParseResult(wordSyncedResult);
                return;
            }
        }

        // Touch the cache mtime when the server still returns valid non-word-synced lyrics.
        if (parseLyricsPayload(json, durationSecs).has_value())
            vast::LyricsCache::save(cacheKey, data, durationSecs);
    });
}
