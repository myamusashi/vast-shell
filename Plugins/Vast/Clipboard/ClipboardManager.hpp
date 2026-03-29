#pragma once

#include "ClipboardModel.hpp"
#include "ClipboardEntry.hpp"

#include <QObject>
#include <QString>
#include <QPointer>

#include <memory>
#include <atomic>

namespace Vast {

    class ClipboardDatabase;
    class ClipboardWatcher;

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

        Q_INVOKABLE [[nodiscard]] bool initialize(const QString& dbPath);

        [[nodiscard]] ClipboardModel*  model() const noexcept;
        [[nodiscard]] int              maxEntries() const noexcept;
        [[nodiscard]] int              maxMegabytes() const noexcept;
        [[nodiscard]] bool             isEnabled() const noexcept;
        [[nodiscard]] QString          activeWindow() const noexcept;

        void                           setMaxEntries(int max);
        void                           setMaxMegabytes(int mb);
        void                           setEnabled(bool enabled);
        void                           setActiveWindow(const QString& window);

        Q_INVOKABLE [[nodiscard]] bool copyToClipboard(qint64 id);
        Q_INVOKABLE void               pin(qint64 id, bool pinned);
        Q_INVOKABLE void               remove(qint64 id);
        Q_INVOKABLE [[nodiscard]] bool clearUnpinned();
        Q_INVOKABLE void               search(const QString& query);
        Q_INVOKABLE void               requestFullEntry(qint64 id);

      signals:
        void maxEntriesChanged();
        void maxMegabytesChanged();
        void enabledChanged();
        void activeWindowChanged();
        void fullEntryReady(QVariantMap entry);

      private:
        void                               setupConnections();
        void                               loadAllEntries();
        void                               pruneIfNeeded();

        QPointer<ClipboardModel>           m_model;
        std::unique_ptr<ClipboardWatcher>  m_watcher;
        std::unique_ptr<ClipboardDatabase> m_database;

        std::atomic<qint64>                m_pendingEntryId{-1};
        std::atomic<int>                   m_maxEntries{500};
        std::atomic<int>                   m_maxMegabytes{64};
        std::atomic<bool>                  m_enabled{true};

        QString                            m_activeWindow;
    };
}
