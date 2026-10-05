import Quickshell
import QtQuick

Scope {
    id: root

    property string debouncedValue: ""
    property int interval: 200
    property string value: ""

    onValueChanged: timer.restart()

    Timer {
        id: timer

        interval: root.interval
        repeat: false

        onTriggered: root.debouncedValue = root.value
    }
}
