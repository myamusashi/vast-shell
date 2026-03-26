#include "ClipboardManager.hpp"
#include "ClipboardDatabase.hpp"
#include "ClipboardWatcher.hpp"

#include <QGuiApplication>
#include <QClipboard>
#include <QMimeData>
#include <QThread>
#include <QImage>
#include <QUrl>

namespace Vast {

    ClipboardManager::ClipboardManager(QObject* parent) : QObject{parent}, m_model{new ClipboardModel{this}}, m_watcher{new ClipboardWatcher{this}} {}

    ClipboardManager::~ClipboardManager() {
        if (m_workerThread && m_workerThread->isRunning()) {
            m_workerThread->quit();
            m_workerThread->wait();
        }
    }

    void ClipboardManager::initialize(const QString& dbPath) {
        // 1. Set up the worker thread and database
        m_workerThread = std::make_unique<QThread>();
        m_database     = std::make_unique<ClipboardDatabase>();

        m_database->moveToThread(m_workerThread.get());

        connectWorkerSignals();

        m_workerThread->start();

        // Open the database on the worker thread via a queued invoke.
        // We use a blocking queued call here so that loadAllEntries() can follow
        // immediately after open() completes.
        QMetaObject::invokeMethod(
            m_database.get(),
            [this, dbPath] {
                if (const auto result = m_database->open(dbPath); !result)
                    qWarning() << "[ClipboardDatabase] open failed:" << result.error();
            },
            Qt::BlockingQueuedConnection);

        // 2. Load existing entries into the model
        loadAllEntries();

        // 3. Start watching the clipboard
        m_watcher->start();
    }

    void ClipboardManager::connectWorkerSignals() {
        // Manager → Database (main → worker)
        connect(this, &ClipboardManager::requestInsert, m_database.get(), &ClipboardDatabase::insert, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestRemove, m_database.get(), &ClipboardDatabase::remove, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestSetPin, m_database.get(), &ClipboardDatabase::setPin, Qt::QueuedConnection);
        connect(this, &ClipboardManager::requestClearUnpinned, m_database.get(), &ClipboardDatabase::clearUnpinned, Qt::QueuedConnection);

        // Database → Manager (worker → main)
        connect(m_database.get(), &ClipboardDatabase::entryInserted, this, &ClipboardManager::onEntryInserted, Qt::QueuedConnection);
        connect(m_database.get(), &ClipboardDatabase::entryRemoved, this, &ClipboardManager::onEntryRemoved, Qt::QueuedConnection);
        connect(m_database.get(), &ClipboardDatabase::entryPinChanged, this, &ClipboardManager::onEntryPinChanged, Qt::QueuedConnection);

        // Watcher → Manager (both main thread — direct connection is fine)
        connect(m_watcher, &ClipboardWatcher::newEntry, this, [this](const ClipboardEntry& entry) {
            // Forward to DB worker
            emit requestInsert(entry);
        });
    }

    void ClipboardManager::loadAllEntries() {
        // Blocking call on worker thread to get the initial entry list.
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

    void ClipboardManager::setMaxEntries(int max) {
        if (m_maxEntries == max)
            return;
        m_maxEntries = max;
        emit         maxEntriesChanged();

        const qint64 maxBytes = static_cast<qint64>(m_maxMegabytes) * 1024 * 1024;
        QMetaObject::invokeMethod(m_database.get(), [this, maxBytes] { m_database->pruneToLimit(m_maxEntries, maxBytes); }, Qt::QueuedConnection);
    }

    void ClipboardManager::setMaxMegabytes(int mb) {
        if (m_maxMegabytes == mb)
            return;
        m_maxMegabytes = mb;
        emit         maxMegabytesChanged();

        const qint64 maxBytes = static_cast<qint64>(mb) * 1024 * 1024;
        QMetaObject::invokeMethod(m_database.get(), [this, maxBytes] { m_database->pruneToLimit(m_maxEntries, maxBytes); }, Qt::QueuedConnection);
    }

    void ClipboardManager::setEnabled(bool enabled) {
        if (m_enabled == enabled)
            return;
        m_enabled = enabled;
        m_watcher->setEnabled(enabled);
        emit enabledChanged();
    }

    void ClipboardManager::copyToClipboard(qint64 id) {
        // We need the full entry (including data BLOB for images).
        // Fetch synchronously from the worker, acceptable since this is
        // a direct user action (button press), not a hot path.
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

        // Temporarily disable the watcher so copying back to clipboard
        // doesn't create a duplicate DB entry.
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

        // Re-enable after a short defer so the clipboard event loop has flushed.
        QMetaObject::invokeMethod(this, [this] { m_watcher->setEnabled(m_enabled); }, Qt::QueuedConnection);
    }

    void ClipboardManager::pin(qint64 id, bool pinned) {
        // Optimistic update: update model immediately for responsive UI.
        m_model->setPinById(id, pinned);
        emit requestSetPin(id, pinned);
    }

    void ClipboardManager::remove(qint64 id) {
        m_model->removeById(id);
        emit requestRemove(id);
    }

    void ClipboardManager::clearUnpinned() {
        // Reset the model and reload (simpler than tracking which ids were deleted).
        emit requestClearUnpinned();

        QMetaObject::invokeMethod(this, [this] { loadAllEntries(); }, Qt::QueuedConnection);
    }

    void ClipboardManager::search(const QString& query) {
        // TODO: wire FuzzyMatcher scoring here once ClipboardManager
        // is connected to the existing Vast::FuzzyMatcher singleton.
        m_model->setFilter(query);
    }

    QVariantMap ClipboardManager::fullEntry(qint64 id) {
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
            return {};

        QVariantMap map;
        map[QStringLiteral("id")]        = entry.id;
        map[QStringLiteral("type")]      = entry.typeString();
        map[QStringLiteral("content")]   = entry.content;
        map[QStringLiteral("mimeType")]  = entry.mimeType;
        map[QStringLiteral("pinned")]    = entry.pinned;
        map[QStringLiteral("sourceApp")] = entry.sourceApp;
        map[QStringLiteral("sizeBytes")] = entry.sizeBytes;
        map[QStringLiteral("timestamp")] = entry.timestamp;

        // Image data: encode to base64 so QML can use:
        //   Image { source: "data:image/png;base64," + entry.imageData }
        if (entry.isImage() && !entry.data.isEmpty())
            map[QStringLiteral("imageData")] = QString::fromLatin1(entry.data.toBase64());

        return map;
    }

    void ClipboardManager::onEntryInserted(ClipboardEntry entry) {
        m_model->prepend(entry);

        const qint64 maxBytes = static_cast<qint64>(m_maxMegabytes) * 1024 * 1024;
        QMetaObject::invokeMethod(m_database.get(), [this, maxBytes] { m_database->pruneToLimit(m_maxEntries, maxBytes); }, Qt::QueuedConnection);
    }

    void ClipboardManager::onEntryRemoved(qint64 id) {
        m_model->removeById(id);
    }

    void ClipboardManager::onEntryPinChanged(qint64 id, bool pinned) {
        m_model->setPinById(id, pinned);
    }
}
