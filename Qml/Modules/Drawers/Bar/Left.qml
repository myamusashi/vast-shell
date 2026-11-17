import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Widgets

RowLayout {
    id: root

    required property ShellScreen monitor

    OsText {
        Layout.alignment: Qt.AlignVCenter
    }

    Workspaces {
        Layout.alignment: Qt.AlignVCenter
        monitor: root.monitor
    }

    WorkspaceName {
        Layout.alignment: Qt.AlignVCenter
    }
}
