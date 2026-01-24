pragma Singleton

import Quickshell

Singleton {
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
        const monthNames = [qsTr("Jan"), qsTr("Feb"), qsTr("Mar"), qsTr("Apr"), qsTr("May"), qsTr("Jun"), qsTr("Jul"), qsTr("Aug"), qsTr("Sep"), qsTr("Oct"), qsTr("Nov"), qsTr("Dec")];
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
        for (const [key, value] of Object.entries(replacements)) {
            result = result.replace(key, value);
        }

        return result;
    }
}
