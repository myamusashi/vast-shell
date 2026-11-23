#include "LyricsProvider.hpp"

#include "LrcParser.hpp"
#include "LyricsCache.hpp"
#include "LyricsScheduler.hpp"
#include "LyricsSelector.hpp"

#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qhashfunctions.h>
#include <qjsonarray.h>
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

namespace {
    constexpr qint64              CACHE_REFRESH_DAYS    = 7;
    constexpr qint64              CACHE_REFRESH_SECONDS = CACHE_REFRESH_DAYS * 24 * 60 * 60;

    [[nodiscard]] QNetworkRequest buildLrclibSearchRequest(const QString& title, const QString& artist) {
        QUrl      url(QStringLiteral("https://lrclib.net/api/search"));
        QUrlQuery query;
        if (!title.isEmpty())
            query.addQueryItem(QStringLiteral("track_name"), title);
        if (!artist.isEmpty())
            query.addQueryItem(QStringLiteral("artist_name"), artist);
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::UserAgentHeader, "Vast Shell/1.0");
        return request;
    }

    [[nodiscard]] QNetworkRequest buildLrclibGetRequest(const QString& title, const QString& artist, double durationSecs) {
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
    fetchFromSearch(title, artist, durationSecs, key);
}

void LyricsProvider::fetchFromSearch(const QString& title, const QString& artist, double durationSecs, const QString& cacheKey) {
    auto* reply = mNam->get(buildLrclibSearchRequest(title, artist));
    connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, durationSecs, cacheKey] {
        reply->deleteLater();
        if (mActiveCacheKey != cacheKey)
            return;

        const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() != QNetworkReply::NoError) {
            if (statusCode >= 400 && statusCode < 500) {
                fetchFromGet(title, artist, durationSecs, cacheKey);
                return;
            }
            setState(State::Error);
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (doc.isArray()) {
            if (const auto selected = vast::LyricsSelector::selectBestCandidate(doc.array(), title, artist, durationSecs)) {
                applyParseResult(selected->parsed);
                vast::LyricsCache::save(cacheKey, QJsonDocument(selected->rawObject).toJson(QJsonDocument::Compact), durationSecs);
                return;
            }
        }

        fetchFromGet(title, artist, durationSecs, cacheKey);
    });
}

void LyricsProvider::fetchFromGet(const QString& title, const QString& artist, double durationSecs, const QString& cacheKey) {
    auto* reply = mNam->get(buildLrclibGetRequest(title, artist, durationSecs));
    connect(reply, &QNetworkReply::finished, this, [this, reply, cacheKey, durationSecs] {
        reply->deleteLater();
        if (mActiveCacheKey != cacheKey)
            return;

        const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (statusCode == 404) {
            setState(State::NotFound);
            return;
        }

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

        if (const auto parsed = vast::LyricsSelector::parsePayload(json, durationSecs)) {
            applyParseResult(*parsed);
            vast::LyricsCache::save(cacheKey, data, durationSecs);
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
    const auto parsed = vast::LyricsSelector::parsePayload(json, cached->durationSecs);
    if (!parsed)
        return false;

    applyParseResult(*parsed);

    const bool isExpired = cached->modifiedAt.isValid() && cached->modifiedAt.secsTo(QDateTime::currentDateTimeUtc()) >= CACHE_REFRESH_SECONDS;
    if (!parsed->wordSynced && isExpired)
        refreshInBackground(title, artist, durationSecs, cacheKey);

    return true;
}

void LyricsProvider::refreshInBackground(const QString& title, const QString& artist, double durationSecs, const QString& cacheKey) {
    if (mRefreshingCacheKey == cacheKey)
        return;
    mRefreshingCacheKey = cacheKey;

    auto* reply = mNam->get(buildLrclibSearchRequest(title, artist));
    connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, cacheKey, durationSecs] {
        reply->deleteLater();
        if (mRefreshingCacheKey == cacheKey)
            mRefreshingCacheKey.clear();

        const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() != QNetworkReply::NoError || statusCode == 429)
            return;

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isArray())
            return;

        if (const auto selected = vast::LyricsSelector::selectBestCandidate(doc.array(), title, artist, durationSecs)) {
            vast::LyricsCache::save(cacheKey, QJsonDocument(selected->rawObject).toJson(QJsonDocument::Compact), durationSecs);
            if (selected->parsed.wordSynced && mActiveCacheKey == cacheKey)
                applyParseResult(selected->parsed);
        }
    });
}
