import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Widgets

RowLayout {
    id: root

    required property ShellScreen monitor

    spacing: Appearance.spacing.normal

    anchors {
        fill: parent
        leftMargin: Appearance.margin.small
    }
    OsText {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }
    Workspaces {
        Layout.alignment: Qt.AlignCenter
        monitor: root.monitor
    }
    WorkspaceName {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }
    Item {
        Layout.fillWidth: true
    }
}
