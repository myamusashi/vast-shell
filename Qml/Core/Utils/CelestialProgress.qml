pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property int nowMinutes: now.getHours() * 60 + now.getMinutes()

    property date         now: new Date()

    function              minutesOf(time) {
        if (!time)
            return -1;
        const parts = String(time).split(":");
        if (parts.length < 2)
            return -1;
        const hours   = Number(parts[0]);
        const minutes = Number(parts[1]);
        if (!isFinite(hours) || !isFinite(minutes))
            return -1;
        return hours * 60 + minutes;
    }

    function              progressBetween(rise, set) {
        const riseMinutes = minutesOf(rise);
        const setMinutes  = minutesOf(set);
        if (riseMinutes < 0 || setMinutes < 0 || riseMinutes === setMinutes)
            return 0;

        if (setMinutes > riseMinutes) {
            if (nowMinutes < riseMinutes)
                return 0;
            if (nowMinutes > setMinutes)
                return 1;
            return (nowMinutes - riseMinutes) / (setMinutes - riseMinutes);
        } else {
            const totalDuration = (1440 - riseMinutes) + setMinutes;
            if (totalDuration <= 0)
                return 0;

            if (nowMinutes >= riseMinutes) {
                const elapsed = nowMinutes - riseMinutes;
                return Math.max(0, Math.min(1, elapsed / totalDuration));
            } else if (nowMinutes <= setMinutes) {
                const elapsed = (1440 - riseMinutes) + nowMinutes;
                return Math.max(0, Math.min(1, elapsed / totalDuration));
            } else {
                return (nowMinutes - setMinutes) < (riseMinutes - nowMinutes) ? 1 : 0;
            }
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }
}
