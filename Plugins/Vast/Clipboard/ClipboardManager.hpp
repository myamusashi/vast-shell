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
        QML_ELEMENT
        QML_SINGLETON
        Q_DISABLE_COPY(ClipboardManager)

        Q_PROPERTY(Vast::ClipboardModel* model READ model CONSTANT)
        Q_PROPERTY(int maxEntries READ maxEntries WRITE setMaxEntries NOTIFY maxEntriesChanged)
        Q_PROPERTY(int maxMegabytes READ maxMegabytes WRITE setMaxMegabytes NOTIFY maxMegabytesChanged)
        Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
        Q_PROPERTY(QString activeWindow READ activeWindow WRITE setActiveWindow NOTIFY activeWindowChanged)

      public:
        explicit ClipboardManager(QObject* parent = nullptr);
        ~ClipboardManager() override;

        Q_INVOKABLE void              initialize(const QString& dbPath);

        [[nodiscard]] ClipboardModel* model() const noexcept;

        [[nodiscard]] int             maxEntries() const noexcept;
        [[nodiscard]] int             maxMegabytes() const noexcept;
        [[nodiscard]] bool            isEnabled() const noexcept;

        void                          setMaxEntries(int max);
        void                          setMaxMegabytes(int mb);
        void                          setEnabled(bool enabled);
        void                          setActiveWindow(const QString& window);

        [[nodiscard]] QString         activeWindow() const noexcept;

        Q_INVOKABLE void              copyToClipboard(qint64 id);
        Q_INVOKABLE void              pin(qint64 id, bool pinned);
        Q_INVOKABLE void              remove(qint64 id);
        Q_INVOKABLE void              clearUnpinned();
        Q_INVOKABLE void              search(const QString& query);
        // keys: id, type, content, imageData, mimeType, timestamp, pinned, sourceApp, sizeBytes.
        Q_INVOKABLE QVariantMap fullEntry(qint64 id);

      signals:
        void maxEntriesChanged();
        void maxMegabytesChanged();
        void enabledChanged();
        void activeWindowChanged();

        void requestInsert(Vast::ClipboardEntry entry);
        void requestRemove(qint64 id);
        void requestSetPin(qint64 id, bool pinned);
        void requestClearUnpinned();
        void requestPrune(int maxEntries, qint64 maxBytes);

      private slots:
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
        QString                            m_activeWindow{};
    };
}
