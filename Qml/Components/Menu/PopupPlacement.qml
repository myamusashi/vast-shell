pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

Scope {
    function resolve(preferredDirection, availableAbove, availableBelow, desiredHeight, maxHeight, minVisibleRows, rowHeight, gap, windowHeight) {
        const minHeight = Math.min(maxHeight, Math.max(80, minVisibleRows * rowHeight));
        let openUpward = false;
        let resolvedMaxHeight = maxHeight;

        if (preferredDirection === "up") {
            openUpward = true;
            resolvedMaxHeight = Math.min(maxHeight, Math.max(minHeight, availableAbove - gap));
        } else if (preferredDirection === "down") {
            resolvedMaxHeight = Math.min(maxHeight, Math.max(minHeight, availableBelow - gap));
        } else {
            const fitsBelow = desiredHeight <= availableBelow - gap;
            const fitsAbove = desiredHeight <= availableAbove - gap;
            openUpward = !fitsBelow && (fitsAbove || availableAbove > availableBelow);
            const available = openUpward ? availableAbove : availableBelow;
            resolvedMaxHeight = Math.min(maxHeight, Math.max(minHeight, available - gap));
        }

        if (windowHeight > 0)
            resolvedMaxHeight = Math.min(resolvedMaxHeight, windowHeight - 24);
        return {
            openUpward: openUpward,
            maxHeight: resolvedMaxHeight
        };
    }
}
