pragma Singleton

import QtQuick
import Quickshell
import Vast.Translation

Singleton {
    id: root

    readonly property var monthNames: {
        TranslationManager.currentLanguage;

        var locale = Qt.locale();
        var names = [];
        for (var i = 0; i < 12; i++) {
            names.push(locale.monthName(i, Locale.ShortFormat));
        }
        return names;
    }

    function timeAgoWithIfElse(timestamp) {
        const date = new Date(timestamp);
        const seconds = Math.floor((new Date() - date) / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);

        if (seconds < 60) {
            if (seconds < 5)
                return qsTr("just now");

            return qsTr("%1 seconds ago").arg(seconds);
        } else if (minutes < 60)
            return minutes === 1 ? qsTr("1 minute ago") : qsTr("%1 minutes ago").arg(minutes);
        else if (hours < 24)
            return hours === 1 ? qsTr("1 hour ago") : qsTr("%1 hours ago").arg(hours);
        else if (days < 30)
            return days === 1 ? qsTr("1 day ago") : qsTr("%1 days ago").arg(days);
        else
            return date.toLocaleString();
    }

    function convertTo12Hour(time24) {
        if (!time24)
            return "";

        const timeStr = time24.includes(" ") ? time24.split(" ")[1] : time24;

        const parts = timeStr.split(":");
        if (parts.length < 2)
            return timeStr;

        let hours = parseInt(parts[0]);
        const minutes = parts[1];

        const period = hours >= 12 ? qsTr("PM") : qsTr("AM");

        if (hours === 0)
            hours = 12;
        else if (hours > 12)
            hours = hours - 12;

        return hours + ":" + minutes + " " + period;
    }

    function convertTo12HourCompact(time24) {
        if (!time24)
            return "";

        const timeStr = time24.includes(" ") ? time24.split(" ")[1] : time24;

        const parts = timeStr.split(":");
        if (parts.length < 2)
            return timeStr;

        let hours = parseInt(parts[0]);
        const minutes = parts[1];

        const period = hours >= 12 ? qsTr("PM") : qsTr("AM");

        if (hours === 0)
            hours = 12;
        else if (hours > 12)
            hours = hours - 12;

        return hours + period;
    }

    function formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        const options = {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            hour12: false
        };
        return date.toLocaleString('en-GB', options);
    }

    function formatTimestampShort(timestamp) {
        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}/${month}/${year}`;
    }

    function formatTimestampWithTime(timestamp) {
        const date = new Date(timestamp);
        const day = String(date.getDate()).padStart(2, '0');
        const month = monthNames[date.getMonth()];
        const year = date.getFullYear();

        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, '0');
        const period = hours >= 12 ? qsTr("PM") : qsTr("AM");

        if (hours === 0)
            hours = 12;
        else if (hours > 12)
            hours = hours - 12;

        return `${day} ${month} ${year}, ${hours}:${minutes} ${period}`;
    }

    function formatTimestampRelative(timestamp) {
        const date = new Date(timestamp);
        return timeAgoWithIfElse(date);
    }

    function formatTimestampCustom(timestamp, format) {
        const date = new Date(timestamp);

        const replacements = {
            'DD': String(date.getDate()).padStart(2, '0'),
            'MM': String(date.getMonth() + 1).padStart(2, '0'),
            'YYYY': date.getFullYear(),
            'YY': String(date.getFullYear()).slice(-2),
            'HH': String(date.getHours()).padStart(2, '0'),
            'mm': String(date.getMinutes()).padStart(2, '0'),
            'ss': String(date.getSeconds()).padStart(2, '0')
        };

        let result = format;
        for (const [key, value] of Object.entries(replacements))
            result = result.replace(key, value);

        return result;
    }

    function formatDuration(seconds) {
        if (seconds === null || seconds === undefined || isNaN(seconds) || seconds <= 0)
            return "0:00";
        const total = Math.floor(seconds);
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const ss = String(s).padStart(2, "0");
        if (h > 0)
            return h + ":" + String(m).padStart(2, "0") + ":" + ss;
        return m + ":" + ss;
    }

    function formatBattery(seconds) {
        if (!(seconds > 0))
            return qsTr("N/A");
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60)
            return minutes + qsTr(" min");
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        return remainingMinutes > 0 ? hours + qsTr(" h ") + remainingMinutes + qsTr(" min") : hours + qsTr(" h");
    }

    function formatClipboard(ms) {
        if (!(ms > 0))
            return "";
        const date = new Date(ms);
        if (isNaN(date.getTime()))
            return "";
        return date.toLocaleString(Qt.locale(), "MMM d, hh:mm ap");
    }

    function formatLauncher(timestamp) {
        const date = new Date(timestamp * 1000);
        if (isNaN(date.getTime()))
            return "";
        return date.toLocaleString("en-US", {
            month: "short",
            day: "numeric",
            hour: "numeric",
            minute: "2-digit",
            hour12: true
        });
    }

    function formatSize(bytes) {
        if (!(bytes >= 0))
            return "";
        if (bytes < 1024)
            return bytes + " " + qsTr("B");
        if (bytes < 1048576)
            return (bytes / 1024).toFixed(1) + " " + qsTr("KiB");
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " " + qsTr("MiB");
        return (bytes / 1073741824).toFixed(1) + " " + qsTr("GiB");
    }

    function formatCompactAge(diffMs) {
        const minutes = Math.floor(diffMs / 60000);
        if (minutes < 1)
            return qsTr("now");
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return `${days}d`;
        if (hours > 0)
            return `${hours}h`;
        return `${minutes}m`;
    }
}
