pragma Singleton

import Quickshell

Singleton {
    readonly property string date: new Date().toLocaleString()
    readonly property string colorReset: "\u001b[0m"
    readonly property string colorRed: "\u001b[31m"
    readonly property string colorBlue: "\u001b[34m"
    readonly property string colorYellow: "\u001b[33m"

    function error(title, message, showDate = false) {
        var timestamp = showDate ? "[" + new Date().toLocaleString() + "] " : "";
        console.log(colorRed + timestamp + "[ERROR] " + title + ": " + message + colorReset);
    }

    function info(title, message, showDate = false) {
        var timestamp = showDate ? "[" + new Date().toLocaleString() + "] " : "";
        console.log(colorBlue + timestamp + "[INFO] " + title + ": " + message + colorReset);
    }

    function warning(title, message, showDate = false) {
        var timestamp = showDate ? "[" + new Date().toLocaleString() + "] " : "";
        console.log(colorYellow + timestamp + "[WARNING] " + title + ": " + message + colorReset);
    }
}
