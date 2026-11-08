#pragma once

#include <qlist.h>

#include <cstddef>
#include <span>

namespace vast {

    template <typename Entry, typename NotifyRow>
    void updateChangedRows(QList<Entry>& currentEntries, std::span<const Entry> nextEntries, const NotifyRow& notifyRowChanged) {
        for (qsizetype rowIndex = 0; rowIndex < currentEntries.size(); ++rowIndex) {
            const Entry& nextEntry = nextEntries[static_cast<std::size_t>(rowIndex)];
            if (currentEntries.at(rowIndex) == nextEntry)
                continue;
            currentEntries[rowIndex] = nextEntry;
            notifyRowChanged(static_cast<int>(rowIndex));
        }
    }

} // namespace vast
