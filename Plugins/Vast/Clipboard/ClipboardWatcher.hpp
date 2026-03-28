#pragma once

#include "ClipboardEntry.hpp"

#include <QObject>
#include <QClipboard>

#include <atomic>

namespace Vast {

    // Listens to QClipboard::dataChanged() on the main thread, classifies the
    // MIME payload, compresses images, computes SHA-256, resolves the source app
    // via hyprctl, then emits newEntry() for ClipboardDatabase to persist
    //
    // Lives on the MAIN thread, QClipboard requires it.
    // Heavy work (image compression) is kept synchronous but brief enough for
    // clipboard events (user-paced, not high-frequency)

    class ClipboardWatcher : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(ClipboardWatcher)

      public:
        explicit ClipboardWatcher(QObject* parent = nullptr);
        ~ClipboardWatcher() override;

        void               start();

        void               setEnabled(bool enabled) noexcept;
        [[nodiscard]] bool isEnabled() const noexcept;

      signals:
        void newEntry(Vast::ClipboardEntry entry);

      private slots:
        void onDataChanged();

      private:
        [[nodiscard]] static std::optional<ClipboardEntry> buildTextEntry(const QClipboard* cb, const QString& sourceApp);
        [[nodiscard]] static std::optional<ClipboardEntry> buildHtmlEntry(const QClipboard* cb, const QString& sourceApp);
        [[nodiscard]] static std::optional<ClipboardEntry> buildFilesEntry(const QClipboard* cb, const QString& sourceApp);

        [[nodiscard]] static QString                       resolveSourceApp();
        [[nodiscard]] static QByteArray                    sha256(const QByteArray& data);
        [[nodiscard]] static QByteArray                    compressImage(const QImage& image);

        static void                                        finalise(ClipboardEntry& entry, const QByteArray& hashPayload, const QString& sourceApp);

        std::atomic<bool>                                  m_enabled{false};
        bool                                               m_started{false};
    };
}
