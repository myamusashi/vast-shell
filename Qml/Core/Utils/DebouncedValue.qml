import Quickshell
import QtQuick

Scope {
    id: root

    property string value: ""
    property string debouncedValue: ""
    property int interval: 200

    onValueChanged: timer.restart()

    Timer {
        id: timer

        repeat: false
        interval: root.interval
        onTriggered: root.debouncedValue = root.value
    }
}
