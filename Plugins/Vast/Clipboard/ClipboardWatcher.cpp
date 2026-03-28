#include "ClipboardWatcher.hpp"
#include "ClipboardManager.hpp"

#include <QGuiApplication>
#include <QBuffer>
#include <QClipboard>
#include <QCryptographicHash>
#include <QDateTime>
#include <QImage>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMimeData>
#include <QProcess>
#include <QUrl>
#include <QtConcurrent>

namespace Vast {

    ClipboardWatcher::ClipboardWatcher(QObject* parent) : QObject{parent} {}

    ClipboardWatcher::~ClipboardWatcher() = default;

    void ClipboardWatcher::start() {
        if (m_started)
            return;

        auto* cb = QGuiApplication::clipboard();
        connect(cb, &QClipboard::dataChanged, this, &ClipboardWatcher::onDataChanged);

        m_started = true;
        m_enabled.store(true, std::memory_order_release);
    }

    void ClipboardWatcher::setEnabled(bool enabled) noexcept {
        m_enabled.store(enabled, std::memory_order_release);
    }

    bool ClipboardWatcher::isEnabled() const noexcept {
        return m_enabled.load(std::memory_order_acquire);
    }

    void ClipboardWatcher::onDataChanged() {
        if (!m_enabled.load(std::memory_order_acquire))
            return;

        const auto* cb   = QGuiApplication::clipboard();
        const auto* mime = cb->mimeData();

        if (!mime || mime->formats().isEmpty())
            return;

        const auto*   manager   = qobject_cast<ClipboardManager*>(parent());
        const QString sourceApp = manager ? manager->activeWindow() : QString{};

        if (mime->hasImage()) {
            const QImage image = cb->image();
            if (!image.isNull()) {
                QtConcurrent::run([this, image, sourceApp]() {
                    const QByteArray png = compressImage(image);
                    if (png.isEmpty())
                        return;

                    ClipboardEntry entry;
                    entry.type     = ClipboardType::Image;
                    entry.mimeType = QStringLiteral("image/png");
                    entry.data     = png;

                    finalise(entry, png, sourceApp);

                    QMetaObject::invokeMethod(this, [this, e = std::move(entry)]() { emit newEntry(e); }, Qt::QueuedConnection);
                });
            }
            return;
        }

        std::optional<ClipboardEntry> entry;
        if (mime->hasHtml())
            entry = buildHtmlEntry(cb, sourceApp);
        else if (mime->hasUrls())
            entry = buildFilesEntry(cb, sourceApp);
        else if (mime->hasText())
            entry = buildTextEntry(cb, sourceApp);

        if (entry.has_value())
            emit newEntry(std::move(*entry));
    }

    std::optional<ClipboardEntry> ClipboardWatcher::buildTextEntry(const QClipboard* cb, const QString& sourceApp) {
        const QString text = cb->text();
        if (text.trimmed().isEmpty())
            return std::nullopt;

        ClipboardEntry entry;
        entry.type     = ClipboardType::Text;
        entry.content  = text;
        entry.mimeType = QStringLiteral("text/plain");

        finalise(entry, text.toUtf8(), sourceApp);
        return entry;
    }

    std::optional<ClipboardEntry> ClipboardWatcher::buildHtmlEntry(const QClipboard* cb, const QString& sourceApp) {
        const auto*   mime  = cb->mimeData();
        const QString html  = mime->html();
        const QString plain = mime->hasText() ? mime->text() : QString{};

        if (html.trimmed().isEmpty())
            return std::nullopt;

        ClipboardEntry entry;
        entry.type     = ClipboardType::Html;
        entry.content  = plain.isEmpty() ? html : plain; // plain for search/preview
        entry.mimeType = QStringLiteral("text/html");

        finalise(entry, html.toUtf8(), sourceApp);
        return entry;
    }

    std::optional<ClipboardEntry> ClipboardWatcher::buildFilesEntry(const QClipboard* cb, const QString& sourceApp) {
        const auto* mime = cb->mimeData();
        const auto  urls = mime->urls();

        if (urls.isEmpty())
            return std::nullopt;

        QStringList paths;
        paths.reserve(urls.size());
        for (const QUrl& url : urls)
            paths.append(url.isLocalFile() ? url.toLocalFile() : url.toString());

        const QString  content = paths.join(u'\n');

        ClipboardEntry entry;
        entry.type     = ClipboardType::Files;
        entry.content  = content;
        entry.mimeType = QStringLiteral("text/uri-list");

        finalise(entry, content.toUtf8(), sourceApp);
        return entry;
    }

    void ClipboardWatcher::finalise(ClipboardEntry& entry, const QByteArray& hashPayload, const QString& sourceApp) {
        entry.hash      = sha256(hashPayload);
        entry.timestamp = QDateTime::currentMSecsSinceEpoch();
        entry.sourceApp = sourceApp;

        entry.sizeBytes = entry.data.isEmpty() ? static_cast<qint64>(entry.content.toUtf8().size()) : static_cast<qint64>(entry.data.size());
    }

    QByteArray ClipboardWatcher::sha256(const QByteArray& data) {
        return QCryptographicHash::hash(data, QCryptographicHash::Sha256);
    }

    QByteArray ClipboardWatcher::compressImage(const QImage& image) {
        constexpr int kMaxDimension = 2048;

        const QImage  scaled =
            (image.width() > kMaxDimension || image.height() > kMaxDimension) ? image.scaled(kMaxDimension, kMaxDimension, Qt::KeepAspectRatio, Qt::SmoothTransformation) : image;

        QByteArray bytes;
        QBuffer    buf{&bytes};
        buf.open(QIODevice::WriteOnly);

        if (!scaled.save(&buf, "PNG", -1))
            return {};

        return bytes;
    }
}
