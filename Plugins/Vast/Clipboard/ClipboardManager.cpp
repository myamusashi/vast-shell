#include "ClipboardManager.hpp"
#include "ClipboardDatabase.hpp"
#include "ClipboardWatcher.hpp"
#include "../Search/FuzzyMatcher.hpp"

#include <QGuiApplication>
#include <QClipboard>
#include <QMimeData>
#include <QThread>
#include <QImage>
#include <QUrl>
#include <QTimer>

namespace Vast {

    ClipboardManager::ClipboardManager(QObject* parent) : QObject{parent}, m_model{new ClipboardModel{this}}, m_watcher{new ClipboardWatcher{this}} {}

    ClipboardManager::~ClipboardManager() {
        if (m_workerThread && m_workerThread->isRunning()) {
            m_workerThread->quit();
            m_workerThread->wait();
        }
    }

    void ClipboardManager::initialize(const QString& dbPath) {
        m_workerThread = std::make_unique<QThread>();
        m_database     = std::make_unique<ClipboardDatabase>();

        m_database->moveToThread(m_workerThread.get());

        connectWorkerSignals();
        m_workerThread->start();

        QMetaObject::invokeMethod(
            m_database.get(),
            [this, dbPath] {
                if (const auto result = m_database->open(dbPath); !result)
                    qWarning() << "[ClipboardDatabase] open failed:" << result.error();
            },
            Qt::BlockingQueuedConnection);

        loadAllEntries();
        m_watcher->start();
    }

    void ClipboardManager::connectWorkerSignals() {
        connect(this, &ClipboardManager::requestInsert, m_database.get(), &ClipboardDatabase::insert, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestRemove, m_database.get(), &ClipboardDatabase::remove, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestSetPin, m_database.get(), &ClipboardDatabase::setPin, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestBumpTimestamp, m_database.get(), &ClipboardDatabase::bumpTimestamp, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestClearUnpinned, m_database.get(), &ClipboardDatabase::clearUnpinned, Qt::QueuedConnection);

        connect(m_database.get(), &ClipboardDatabase::entryInserted, this, &ClipboardManager::onEntryInserted, Qt::QueuedConnection);
        connect(m_database.get(), &ClipboardDatabase::entryRemoved, this, &ClipboardManager::onEntryRemoved, Qt::QueuedConnection);
        connect(m_database.get(), &ClipboardDatabase::entryPinChanged, this, &ClipboardManager::onEntryPinChanged, Qt::QueuedConnection);

        connect(this, &ClipboardManager::_fullEntryFetched, this, &ClipboardManager::onFullEntryFetched, Qt::QueuedConnection);

        connect(m_watcher, &ClipboardWatcher::newEntry, this, [this](const ClipboardEntry& entry) { emit requestInsert(entry); });
    }

    void ClipboardManager::loadAllEntries() {
        QList<ClipboardEntry> entries;
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, &entries] {
                auto result = m_database->fetchAll();
                if (result)
                    entries = std::move(*result);
                else
                    qWarning() << "[ClipboardDatabase] fetchAll failed:" << result.error();
            },
            Qt::BlockingQueuedConnection);

        m_model->reset(std::move(entries));
    }

    ClipboardModel* ClipboardManager::model() const noexcept {
        return m_model;
    }

    int ClipboardManager::maxEntries() const noexcept {
        return m_maxEntries;
    }

    int ClipboardManager::maxMegabytes() const noexcept {
        return m_maxMegabytes;
    }

    bool ClipboardManager::isEnabled() const noexcept {
        return m_enabled;
    }

    QString ClipboardManager::activeWindow() const noexcept {
        return m_activeWindow;
    }

    void ClipboardManager::setMaxEntries(int max) {
        if (m_maxEntries == max)
            return;

        m_maxEntries = max;
        emit         maxEntriesChanged();
        const qint64 maxBytes = static_cast<qint64>(m_maxMegabytes) * 1024 * 1024;
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, maxBytes] {
                if (const auto r = m_database->pruneToLimit(m_maxEntries, maxBytes); !r)
                    qWarning() << "[ClipboardDatabase] pruneToLimit failed:" << r.error();
            },
            Qt::QueuedConnection);
    }

    void ClipboardManager::setMaxMegabytes(int mb) {
        if (m_maxMegabytes == mb)
            return;
        m_maxMegabytes = mb;
        emit         maxMegabytesChanged();
        const qint64 maxBytes = static_cast<qint64>(mb) * 1024 * 1024;
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, maxBytes] {
                if (const auto r = m_database->pruneToLimit(m_maxEntries, maxBytes); !r)
                    qWarning() << "[ClipboardDatabase] pruneToLimit failed:" << r.error();
            },
            Qt::QueuedConnection);
    }

    void ClipboardManager::setEnabled(bool enabled) {
        if (m_enabled == enabled)
            return;
        m_enabled = enabled;
        m_watcher->setEnabled(enabled);
        emit enabledChanged();
    }

    void ClipboardManager::setActiveWindow(const QString& window) {
        if (m_activeWindow == window)
            return;
        m_activeWindow = window;
        emit activeWindowChanged();
    }

    void ClipboardManager::requestFullEntry(qint64 id) {
        m_pendingEntryId = id;

        if (id < 0)
            return;

        QMetaObject::invokeMethod(
            m_database.get(),
            [this, id] {
                auto result = m_database->fetchById(id);
                if (!result) {
                    qWarning() << "[ClipboardDatabase] fetchById failed:" << result.error();
                    return;
                }
                emit _fullEntryFetched(std::move(*result));
            },
            Qt::QueuedConnection);
    }

    void ClipboardManager::onFullEntryFetched(ClipboardEntry entry) {
        // If the user moved to a different entry while the worker was busy,
        // this response is stale, drop it silently
        if (entry.id != m_pendingEntryId)
            return;

        QVariantMap map;
        map[QStringLiteral("id")]        = entry.id;
        map[QStringLiteral("type")]      = entry.typeString();
        map[QStringLiteral("content")]   = entry.content;
        map[QStringLiteral("mimeType")]  = entry.mimeType;
        map[QStringLiteral("pinned")]    = entry.pinned;
        map[QStringLiteral("sourceApp")] = entry.sourceApp;
        map[QStringLiteral("sizeBytes")] = entry.sizeBytes;
        map[QStringLiteral("timestamp")] = entry.timestamp;

        if (entry.isImage() && !entry.data.isEmpty())
            map[QStringLiteral("imageData")] = QString::fromLatin1(entry.data.toBase64());

        emit fullEntryReady(map);
    }

    void ClipboardManager::copyToClipboard(qint64 id) {
        // copyToClipboard is a deliberate user action, not on a hot path,
        // so blocking is acceptable here. The BLOB is needed immediately
        // to set clipboard data before returning
        ClipboardEntry entry;
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, id, &entry] {
                auto result = m_database->fetchById(id);
                if (result)
                    entry = std::move(*result);
            },
            Qt::BlockingQueuedConnection);

        if (entry.id < 0)
            return;

        m_watcher->setEnabled(false);

        auto* mime = new QMimeData{};
        switch (entry.type) {
            case ClipboardType::Text: mime->setText(entry.content); break;
            case ClipboardType::Html:
                mime->setHtml(entry.content);
                mime->setText(entry.content);
                break;
            case ClipboardType::Image: {
                QImage img;
                img.loadFromData(entry.data, "PNG");
                if (!img.isNull())
                    mime->setImageData(std::move(img));
                break;
            }
            case ClipboardType::Files: {
                const QStringList paths = entry.content.split(u'\n', Qt::SkipEmptyParts);
                QList<QUrl>       urls;
                urls.reserve(paths.size());
                for (const QString& p : paths)
                    urls.append(QUrl::fromLocalFile(p));
                mime->setUrls(urls);
                break;
            }
        }

        QGuiApplication::clipboard()->setMimeData(mime);
        m_model->bumpToTop(id);

        // Fix 1a: only bump the DB timestamp — do NOT re-insert.
        // requestInsert would trigger entryInserted → onEntryInserted → prepend(),
        // causing a second model reorder on top of bumpToTop() above.
        emit requestBumpTimestamp(id);

        QTimer::singleShot(500, this, [this] { m_watcher->setEnabled(m_enabled); });
    }

    void ClipboardManager::pin(qint64 id, bool pinned) {
        m_model->setPinById(id, pinned);
        emit requestSetPin(id, pinned);
    }

    void ClipboardManager::remove(qint64 id) {
        m_model->removeById(id);
        emit requestRemove(id);
    }

    void ClipboardManager::clearUnpinned() {
        emit requestClearUnpinned();
        QMetaObject::invokeMethod(this, [this] { loadAllEntries(); }, Qt::QueuedConnection);
    }

    void ClipboardManager::search(const QString& query) {
        if (query.isEmpty()) {
            m_model->setFilter({}, {});
            return;
        }

        const auto&                  entries = m_model->allEntries();
        QList<QPair<double, qint64>> scored;
        scored.reserve(entries.size());

        for (const auto& entry : entries) {
            const QString haystack = entry.isImage() ? entry.sourceApp : entry.content.left(500) + u' ' + entry.sourceApp;

            const double  s = FuzzyMatcher::fuzzyScore(query, haystack);
            if (s > 0.0)
                scored.append({s, entry.id});
        }

        std::ranges::sort(scored, [](const auto& a, const auto& b) { return a.first > b.first; });

        QList<qint64> orderedIds;
        orderedIds.reserve(scored.size());
        for (const auto& [s, id] : scored)
            orderedIds.append(id);

        m_model->setFilter(query, orderedIds);
    }

    void ClipboardManager::onEntryInserted(ClipboardEntry entry) {
        m_model->prepend(entry);

        const qint64 maxBytes = static_cast<qint64>(m_maxMegabytes) * 1024 * 1024;
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, maxBytes] {
                if (const auto r = m_database->pruneToLimit(m_maxEntries, maxBytes); !r)
                    qWarning() << "[ClipboardDatabase] pruneToLimit failed:" << r.error();
            },
            Qt::QueuedConnection);
    }

    void ClipboardManager::onEntryRemoved(qint64 id) {
        m_model->removeById(id);
    }

    void ClipboardManager::onEntryPinChanged(qint64 id, bool pinned) {
        m_model->setPinById(id, pinned);
    }

}
