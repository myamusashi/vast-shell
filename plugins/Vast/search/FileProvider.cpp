#include "FileProvider.hpp"
#include "FuzzyMatcher.hpp"

#include <QDirIterator>
#include <QFileInfo>
#include <QMimeType>
#include <QFuture>
#include <QtConcurrent/QtConcurrent>
#include <algorithm>

FileProvider::FileProvider(QObject* parent) : QObject(parent) {
    m_watcher = new QFutureWatcher<QList<SearchResult*>>(this);
    connect(m_watcher, &QFutureWatcher<QList<SearchResult*>>::finished, this, [this]() { emit filesReady(m_watcher->result()); });
}

FileProvider::~FileProvider() {
    cancel();
}

void FileProvider::searchAsync(const QString& query, const QString& rootDir, int maxDepth, double threshold) {
    cancel();
    emit                          searchStarted();

    const QString                 q   = query;
    const QString                 dir = rootDir;
    const int                     dep = maxDepth;
    const double                  thr = threshold;

    QFuture<QList<SearchResult*>> future = QtConcurrent::run([this, q, dir, dep, thr]() {
        const QList<FileEntry> entries = collectFiles(dir, dep);
        return scoreEntries(entries, q, thr);
    });

    m_watcher->setFuture(future);
}

QList<SearchResult*> FileProvider::searchSync(const QString& query, const QString& rootDir, int maxDepth, double threshold) const {
    return scoreEntries(collectFiles(rootDir, maxDepth), query, threshold);
}

void FileProvider::cancel() {
    if (m_watcher->isRunning()) {
        m_watcher->cancel();
        m_watcher->waitForFinished();
    }
}

QList<FileProvider::FileEntry> FileProvider::collectFiles(const QString& rootDir, int maxDepth) {
    QList<FileEntry> entries;
    QMimeDatabase    mimeDb;

    const qsizetype  rootDepth = rootDir.count('/');

    QDirIterator     it(rootDir, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Hidden, QDirIterator::Subdirectories);

    while (it.hasNext()) {
        it.next();
        const QFileInfo fi = it.fileInfo();

        const qsizetype depth = fi.filePath().count('/') - rootDepth;
        if (depth > maxDepth)
            continue;

        const QString name = fi.fileName();
        if (name.startsWith('.'))
            continue;
        if (fi.isDir()) {
            static const QStringList skipDirs = {"node_modules", ".git", ".svn", ".hg", "__pycache__", "target", "build", ".cache"};
            if (skipDirs.contains(name))
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

    if (iconMap.contains(mimeType))
        return iconMap.value(mimeType);

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

QList<SearchResult*> FileProvider::scoreEntries(const QList<FileEntry>& entries, const QString& query, double threshold) const {
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

    std::sort(hits.begin(), hits.end(), [](const Hit& a, const Hit& b) {
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

        QString subtitle = e.path;
        subtitle.chop(e.name.length() + (e.path.endsWith(e.name) ? 0 : 1));

        results.append(SearchResult::makeFile(e.name, subtitle, e.icon, h.score, data, ranges, nullptr));
    }

    return results;
}
