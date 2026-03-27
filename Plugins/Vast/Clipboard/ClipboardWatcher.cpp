#include "ClipboardWatcher.hpp"

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
#include <QDebug>

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
        if (!m_enabled.load(std::memory_order_acquire)) {
            qDebug() << "[ClipboardWatcher] dataChanged ignored because disabled";
            return;
        }

        qDebug() << "[ClipboardWatcher] dataChanged received!";

        const auto* cb   = QGuiApplication::clipboard();
        const auto* mime = cb->mimeData();

        if (!mime || mime->formats().isEmpty()) {
            qDebug() << "[ClipboardWatcher] No valid formats, ignoring" << (mime ? mime->formats() : QStringList{});
            return;
        }

        qDebug() << "[ClipboardWatcher] Formats:" << mime->formats();

        // Resolve source app FIRST, while the clipboard owner's window is still
        // active (hyprctl reads the currently focused window at call-time)
        const QString sourceApp = resolveSourceApp();

        // Priority order: image > html > files > plain text
        // HTML is checked before plain text because rich text apps set both
        std::optional<ClipboardEntry> entry;

        if (mime->hasImage())
            entry = buildImageEntry(cb, sourceApp);
        else if (mime->hasHtml())
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

        // Hash the html payload for accurate deduplication.
        finalise(entry, html.toUtf8(), sourceApp);
        return entry;
    }

    std::optional<ClipboardEntry> ClipboardWatcher::buildImageEntry(const QClipboard* cb, const QString& sourceApp) {
        const QImage image = cb->image();
        if (image.isNull())
            return std::nullopt;

        const QByteArray png = compressImage(image);
        if (png.isEmpty())
            return std::nullopt;

        ClipboardEntry entry;
        entry.type     = ClipboardType::Image;
        entry.mimeType = QStringLiteral("image/png");
        entry.data     = png;
        // Leave content empty — image entries match on sourceApp only in fuzzy search.

        finalise(entry, png, sourceApp);
        return entry;
    }

    std::optional<ClipboardEntry> ClipboardWatcher::buildFilesEntry(const QClipboard* cb, const QString& sourceApp) {
        const auto* mime = cb->mimeData();
        const auto  urls = mime->urls();

        if (urls.isEmpty())
            return std::nullopt;

        // Store as newline-separated local paths (or URLs for remote ones).
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

        // sizeBytes reflects actual storage cost:
        // text entries: UTF-8 byte count; image entries: compressed PNG size
        entry.sizeBytes = entry.data.isEmpty() ? static_cast<qint64>(entry.content.toUtf8().size()) : static_cast<qint64>(entry.data.size());
    }

    QString ClipboardWatcher::resolveSourceApp() {
        // hyprctl is Hyprland-specific. On other compositors this returns empty,
        // which is a safe fallback, the entry is still stored without a source
        QProcess proc;
        proc.start(QStringLiteral("hyprctl"), QStringList{QStringLiteral("-j"), QStringLiteral("activewindow")});

        if (!proc.waitForFinished(300 /*ms*/))
            return {};

        const auto json = QJsonDocument::fromJson(proc.readAllStandardOutput());
        if (json.isNull() || !json.isObject())
            return {};

        return json.object().value(QStringLiteral("class")).toString();
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

        // PNG quality argument is ignored by Qt's PNG encoder (it controls zlib compression level via negative values; -1 = default)
        if (!scaled.save(&buf, "PNG", -1))
            return {};

        return bytes;
    }

}
