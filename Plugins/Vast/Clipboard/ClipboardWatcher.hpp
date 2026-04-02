#pragma once

#include "ClipboardEntry.hpp"

#include <QObject>
#include <QClipboard>
#include <QPointer>
#include <QHash>
#include <QByteArray>

#include <optional>

namespace Vast {

    class ClipboardWatcher : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(ClipboardWatcher)

      public:
        explicit ClipboardWatcher(QObject* parent = nullptr);
        ~ClipboardWatcher() override;

        void               start();

        void               setEnabled(bool enabled) noexcept;
        void               setSelfCopyHash(const QByteArray& hash) noexcept;
        [[nodiscard]] bool isEnabled() const noexcept;

      signals:
        void newEntry(Vast::ClipboardEntry entry);

      private slots:
        void onDataChanged();

      private:
        [[nodiscard]] static std::optional<ClipboardEntry> buildTextEntry(const QClipboard* cb, const QString& sourceApp);
        [[nodiscard]] static std::optional<ClipboardEntry> buildHtmlEntry(const QClipboard* cb, const QString& sourceApp);
        [[nodiscard]] static std::optional<ClipboardEntry> buildFilesEntry(const QClipboard* cb, const QString& sourceApp);

        [[nodiscard]] static QByteArray                    sha256(const QByteArray& data);
        [[nodiscard]] static QByteArray                    compressImage(const QImage& image);

        static void                                        finalise(ClipboardEntry& entry, const QByteArray& hashPayload, const QString& sourceApp);

        bool                                               m_enabled{false};
        QHash<QByteArray, int>                             m_selfCopyHashes{};
        bool                                               m_started{false};
        QByteArray                                         m_lastImageHash{};
    };
}
