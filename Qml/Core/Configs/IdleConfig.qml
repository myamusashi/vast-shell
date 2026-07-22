import QtQuick
import Quickshell.Io

JsonObject {
    property bool enabled: true
    property list<var> timeouts: [
        {
            timeoutMonitor: 60,
            "on-timeout": "",
            "on-resume": ""
        },
    ]
}
