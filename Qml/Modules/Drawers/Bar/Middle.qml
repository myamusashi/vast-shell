pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Widgets

RowLayout {
    id: root

    required property ShellScreen monitor

    Mpris {
        Layout.alignment: Qt.AlignVCenter
        monitor: root.monitor
    }

    RecordIndicator {
        Layout.alignment: Qt.AlignVCenter
    }
}
