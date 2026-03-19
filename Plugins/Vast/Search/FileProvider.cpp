#include "FileProvider.hpp"
#include "FuzzyMatcher.hpp"

#include <QDirIterator>
#include <QFileInfo>
#include <QMimeType>
#include <QFuture>
#include <QtConcurrent/QtConcurrent>
#include <algorithm>

FileProvider::FileProvider(QObject* parent) : QObject(parent) {
    m_watcher      = new QFutureWatcher<QList<SearchResult*>>(this);
    m_cacheWatcher = new QFutureWatcher<QList<FileEntry>>(this);

    connect(m_cacheWatcher, &QFutureWatcher<QList<FileEntry>>::finished, this, [this]() {
        m_cachedEntries = m_cacheWatcher->result();
        m_cacheReady    = true;
    });
}

FileProvider::~FileProvider() {
    cancel();
}

void FileProvider::warmCache(const QString& rootDir, int maxDepth) {
    if (m_cacheReady && m_cachedDir == rootDir && m_cachedDepth == maxDepth)
        return;

    m_cachedDir   = rootDir;
    m_cachedDepth = maxDepth;
    m_cacheReady  = false;

    m_cacheWatcher->setFuture(QtConcurrent::run([rootDir, maxDepth]() { return collectFiles(rootDir, maxDepth); }));
}

void FileProvider::searchAsync(const QString& query, const QString& rootDir, int maxDepth, double threshold) {
    cancel();
    emit searchStarted();

    // use cache if available, otherwise collect inline
    QList<FileEntry>              entries = m_cacheReady && m_cachedDir == rootDir && m_cachedDepth == maxDepth ? m_cachedEntries : collectFiles(rootDir, maxDepth);

    QFuture<QList<SearchResult*>> future = QtConcurrent::run([this, entries, query, threshold]() {
        auto  results    = scoreEntries(entries, query, threshold, nullptr);
        auto* mainThread = QCoreApplication::instance()->thread();
        for (SearchResult* r : results)
            r->moveToThread(mainThread);
        return results;
    });

    m_watcher->setFuture(future);
}

QList<SearchResult*> FileProvider::searchSync(const QString& query, const QString& rootDir, int maxDepth, double threshold) const {
    return scoreEntries(collectFiles(rootDir, maxDepth), query, threshold, nullptr);
}

void FileProvider::cancel() {
    if (m_watcher->isRunning()) {
        m_watcher->cancel();
        m_watcher->waitForFinished();
    }
}

QList<FileProvider::FileEntry> FileProvider::collectFiles(const QString& rootDir, int maxDepth) {
    QList<FileEntry>           entries;
    static const QMimeDatabase mimeDb;

    const qsizetype            rootDepth = rootDir.count('/');

    QDirIterator               it(rootDir, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        const QFileInfo fi = it.fileInfo();

        const qsizetype depth = fi.filePath().count('/') - rootDepth;
        if (depth > static_cast<qsizetype>(maxDepth))
            continue;

        const QString name = fi.fileName();
        if (name.startsWith('.'))
            continue;

        if (fi.isDir()) {
            static constexpr std::array skipDirs{"node_modules", ".git", ".svn", ".hg", "__pycache__", "target", "build", ".cache"};
            if (std::ranges::contains(skipDirs, std::string_view(name.toStdString())))
                continue;
        }

        FileEntry e;
        e.name  = name;
        e.path  = fi.filePath();
        e.isDir = fi.isDir();

        if (!e.isDir) {
            const QMimeType mime = mimeDb.mimeTypeForFile(fi);
            e.mimeType           = mime.name();
            e.icon               = mimeIcon(e.mimeType, false);
        } else {
            e.icon = "folder";
        }

        entries.append(std::move(e));
    }

    return entries;
}

QString FileProvider::mimeIcon(const QString& mimeType, bool isDir) {
    if (isDir)
        return "folder";

    static const QHash<QString, QString> iconMap = {
        {"application/pdf", "application-pdf"},
        {"text/plain", "text-plain"},
        {"text/html", "text-html"},
        {"text/x-script.python", "text-x-python"},
        {"text/x-csrc", "text-x-csrc"},
        {"text/x-c++src", "text-x-c++src"},
        {"application/json", "application-json"},
        {"image/png", "image-png"},
        {"image/jpeg", "image-jpeg"},
        {"image/svg+xml", "image-svg+xml"},
        {"audio/mpeg", "audio-x-generic"},
        {"audio/flac", "audio-x-generic"},
        {"video/mp4", "video-x-generic"},
        {"application/zip", "application-x-archive"},
        {"application/x-tar", "application-x-archive"},
        {"application/gzip", "application-x-archive"},
        {"application/vnd.oasis.opendocument.text", "libreoffice-odt"},
        {"application/msword", "application-msword"},
        {"application/x-executable", "application-x-executable"},
    };

    if (auto it = iconMap.find(mimeType); it != iconMap.end())
        return it.value();

    const QString super = mimeType.section('/', 0, 0);
    if (super == "image")
        return "image-x-generic";
    if (super == "audio")
        return "audio-x-generic";
    if (super == "video")
        return "video-x-generic";
    if (super == "text")
        return "text-x-generic";

    return "unknown";
}

QList<SearchResult*> FileProvider::scoreEntries(const QList<FileEntry>& entries, const QString& query, double threshold, QObject* parent) const {
    if (query.trimmed().isEmpty())
        return {};

    struct Hit {
        const FileEntry* entry;
        double           score;
    };
    QList<Hit> hits;

    for (const FileEntry& e : entries) {
        const double s = FuzzyMatcher::fuzzyScore(query, e.name);
        if (s >= threshold)
            hits.append({&e, s});
    }

    std::ranges::sort(hits, [](const Hit& a, const Hit& b) {
        if (std::abs(a.score - b.score) < 0.001)
            return a.entry->name.length() < b.entry->name.length();
        return a.score > b.score;
    });

    QList<SearchResult*> results;
    results.reserve(hits.size());

    for (const Hit& h : hits) {
        const FileEntry& e = *h.entry;

        QVariantMap      data;
        data["path"]     = e.path;
        data["isDir"]    = e.isDir;
        data["mimeType"] = e.mimeType;

        const QVariantList ranges = FuzzyMatcher::highlightRanges(e.name, query);

        QString            subtitle = e.path;
        subtitle.chop(e.name.length() + (e.path.endsWith(e.name) ? 0 : 1));

        results.append(SearchResult::makeFile(e.name, subtitle, e.icon, h.score, data, ranges, parent));
    }

    return results;
}
