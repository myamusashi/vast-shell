#pragma once

#include "ClipboardModel.hpp"
#include "ClipboardEntry.hpp"

#include <QObject>
#include <QThread>
#include <QString>

#include <memory>

namespace Vast {

    class ClipboardDatabase;
    class ClipboardWatcher;

    // Threading layout:
    //   Main thread  — ClipboardManager, ClipboardModel, ClipboardWatcher
    //   Worker thread — ClipboardDatabase

    class ClipboardManager : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(ClipboardManager)

        Q_PROPERTY(Vast::ClipboardModel* model READ model CONSTANT)

        Q_PROPERTY(int maxEntries READ maxEntries WRITE setMaxEntries NOTIFY maxEntriesChanged)

        Q_PROPERTY(int maxMegabytes READ maxMegabytes WRITE setMaxMegabytes NOTIFY maxMegabytesChanged)

        Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)

      public:
        explicit ClipboardManager(QObject* parent = nullptr);
        ~ClipboardManager() override;

        // Called once by the plugin init path.
        void                          initialize(const QString& dbPath);

        [[nodiscard]] ClipboardModel* model() const noexcept;

        [[nodiscard]] int             maxEntries() const noexcept;
        [[nodiscard]] int             maxMegabytes() const noexcept;
        [[nodiscard]] bool            isEnabled() const noexcept;

        void                          setMaxEntries(int max);
        void                          setMaxMegabytes(int mb);
        void                          setEnabled(bool enabled);

        // Copy an existing entry back to the system clipboard.
        Q_INVOKABLE void copyToClipboard(qint64 id);

        // Toggle pinned state.
        Q_INVOKABLE void pin(qint64 id, bool pinned);

        // Hard-delete one entry (cannot delete pinned unless forced).
        Q_INVOKABLE void remove(qint64 id);

        // Delete all unpinned entries.
        Q_INVOKABLE void clearUnpinned();

        // Run fuzzy search and update the model's visible filter.
        Q_INVOKABLE void search(const QString& query);

        // Returns the full entry for preview (including base64-encoded image data).
        // QML receives a QVariantMap with keys: id, type, content, imageData,
        // mimeType, timestamp, pinned, sourceApp, sizeBytes.
        Q_INVOKABLE QVariantMap fullEntry(qint64 id);

      signals:
        void maxEntriesChanged();
        void maxMegabytesChanged();
        void enabledChanged();

        // Forwarded to ClipboardDatabase on the worker thread (QueuedConnection).
        void requestInsert(Vast::ClipboardEntry entry);
        void requestRemove(qint64 id);
        void requestSetPin(qint64 id, bool pinned);
        void requestClearUnpinned();
        void requestPrune(int maxEntries, qint64 maxBytes);

      private slots:
        // Receives entryInserted from ClipboardDatabase (worker thread → main).
        void onEntryInserted(Vast::ClipboardEntry entry);
        void onEntryRemoved(qint64 id);
        void onEntryPinChanged(qint64 id, bool pinned);

      private:
        void                               connectWorkerSignals();
        void                               loadAllEntries();

        ClipboardModel*                    m_model   = nullptr;
        ClipboardWatcher*                  m_watcher = nullptr;
        std::unique_ptr<QThread>           m_workerThread{};
        std::unique_ptr<ClipboardDatabase> m_database{};

        int                                m_maxEntries   = 500;
        int                                m_maxMegabytes = 64;
        bool                               m_enabled      = true;
    };
}
