pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root
    function clampWidth(width, minimum, maximum) {
        return Math.min(maximum, Math.max(minimum, width));
    }

    function clampHeight(count, rowHeight, spacing, maximum) {
        const itemCount = Math.max(0, Number(count) || 0);
        const rows = itemCount * rowHeight + Math.max(0, itemCount - 1) * spacing;
        return Math.min(maximum, rows);
    }

    function computeMaxWidth(items, measure, maximum, padding) {
        let width = 0;
        for (const item of items ?? [])
            width = Math.max(width, Number(measure(item)) || 0);
        return Math.min(maximum, width + padding);
    }

    function computeActiveWidth(items, measure, minimum, padding, emptyWidth) {
        const values = items ?? [];
        if (values.length === 0)
            return emptyWidth;
        let width = 0;
        for (const item of values)
            width = Math.max(width, Number(measure(item)) || 0);
        return Math.max(minimum, width + padding);
    }
}
