pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function clamp(value, maximum = 1.0) {
        return Math.max(0.0, Math.min(maximum, Number(value) || 0));
    }

    function fromPercent(percent, maximum = 1.0) {
        return clamp(Number(percent) / 100, maximum);
    }

    function toPercent(value) {
        return Math.round(clamp(value) * 100);
    }
}
