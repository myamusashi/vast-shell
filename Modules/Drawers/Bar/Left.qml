import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Widgets

RowLayout {
    id: root

    anchors {
        fill: parent
        leftMargin: Appearance.margin.small
    }

    required property ShellScreen monitor

    spacing: Appearance.spacing.normal

    OsText {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }

    Workspaces {
        monitor: root.monitor
        Layout.alignment: Qt.AlignCenter
    }

    WorkspaceName {
        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    }

    Item {
        Layout.fillWidth: true
    }
}
