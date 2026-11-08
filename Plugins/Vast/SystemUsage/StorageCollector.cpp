#include "StorageCollector.hpp"

#include <qlist.h>
#include <qstorageinfo.h>
#include <qstring.h>

namespace vast {

    sysusage::StorageSummary StorageCollector::collect() {
        const auto                          mountedVolumes = QStorageInfo::mountedVolumes();
        QList<sysusage::FilesystemRawEntry> rawEntries;
        rawEntries.reserve(mountedVolumes.size());

        for (const auto& storage : mountedVolumes) {
            if (!storage.isValid() || !storage.isReady())
                continue;

            const QString device = QString::fromUtf8(storage.device());
            if (!device.startsWith(u"/dev/") || device.startsWith(u"/dev/loop"))
                continue;

            const qint64 totalBytes = storage.bytesTotal();
            if (totalBytes <= 0)
                continue;

            const qint64  availableBytes = std::max<qint64>(0, storage.bytesAvailable());
            const auto    totalKiB       = static_cast<quint64>(totalBytes / 1024);
            const auto    freeKiB        = static_cast<quint64>(availableBytes / 1024);
            const quint64 usedKiB        = (totalKiB >= freeKiB) ? (totalKiB - freeKiB) : 0;

            rawEntries.append(sysusage::FilesystemRawEntry{
                .deviceName     = device,
                .filesystemType = QString::fromUtf8(storage.fileSystemType()),
                .mountPoint     = storage.rootPath(),
                .usedKiB        = usedKiB,
                .freeKiB        = freeKiB,
                .totalKiB       = totalKiB,
            });
        }

        return sysusage::deduplicateFilesystems(rawEntries);
    }

} // namespace vast
