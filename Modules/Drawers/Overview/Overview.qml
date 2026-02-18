pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

// Thx Confusion_18 for your simple Overview code
StyledRect {
    id: root

    property bool isOverviewOpen: GlobalStates.isOverviewOpen
    property real spacing: Appearance.spacing.normal
    property real columns: 5
    property real rows: 2
    property real contentWidth: (Hypr.focusedMonitor?.width / Hypr.focusedMonitor?.scale) / 1.5
    property real tileWidth: (contentWidth - spacing * (columns + 1)) / columns
    property real tileHeight: tileWidth * 9 / 16

    color: GlobalStates.drawerColors
    implicitWidth: contentWidth
    implicitHeight: tileHeight * rows + spacing * (rows + 1)
    x: GlobalStates.isOverviewOpen ? (parent.width - width) / 2 : -width
    y: GlobalStates.isOverviewOpen ? (parent.height - height) / 2 : -height

    Behavior on x {
        NAnim {}
    }

    GridLayout {
        id: overviewLayout

        anchors {
            fill: parent
            margins: root.spacing
        }
        columns: root.columns
        rows: root.rows
        rowSpacing: 8
        columnSpacing: 8

        Repeater {
            model: root.rows * root.columns

            delegate: WorkspaceView {
                id: delegate

                parentWindow: root
                implicitWidth: root.tileWidth
                implicitHeight: root.tileHeight

                DropArea {
                    anchors.fill: parent
                    onDropped: drag => {
                        var address = drag.source.address;

                        Hypr.dispatch("movetoworkspacesilent " + (delegate.index + 1) + ", address:" + address);
                        Hyprland.refreshWorkspaces();
                        Hyprland.refreshMonitors();
                        Hyprland.refreshToplevels();
                    }
                }
            }
        }
    }
}
