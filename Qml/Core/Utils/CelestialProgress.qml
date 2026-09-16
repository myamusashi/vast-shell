pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property date now: new Date()
    readonly property int nowMinutes: now.getHours() * 60 + now.getMinutes()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function minutesOf(time) {
        if (!time)
            return -1;
        const parts = String(time).split(":");
        if (parts.length < 2)
            return -1;
        const hours = Number(parts[0]);
        const minutes = Number(parts[1]);
        if (!isFinite(hours) || !isFinite(minutes))
            return -1;
        return hours * 60 + minutes;
    }

    function progressBetween(rise, set) {
        const riseMinutes = minutesOf(rise);
        const setMinutes = minutesOf(set);
        if (riseMinutes < 0 || setMinutes < 0 || setMinutes <= riseMinutes)
            return 0;
        return Math.max(0, Math.min(1, (nowMinutes - riseMinutes) / (setMinutes - riseMinutes)));
    }
}
