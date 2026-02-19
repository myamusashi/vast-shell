pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

// Thx Confusion_18 for your simple Overview code
ClippingWrapperRectangle {
    id: root

    anchors.centerIn: parent

    property bool isOverviewOpen: GlobalStates.isOverviewOpen
    property real spacing: Appearance.spacing.normal
    property real columns: 5
    property real rows: 2
    property real contentWidth: (Hypr.focusedMonitor?.width / Hypr.focusedMonitor?.scale) / 1.5
    property real tileWidth: (contentWidth - spacing * (columns + 1)) / columns
    property real tileHeight: tileWidth * 9 / 16

    border {
        color: GlobalStates.isOverviewOpen ? Colours.m3Colors.m3Outline : "transparent"
        width: GlobalStates.isOverviewOpen ? 2 : 0
    }
    color: GlobalStates.drawerColors
    implicitWidth: contentWidth
    implicitHeight: GlobalStates.isOverviewOpen ? tileHeight * rows + spacing * (rows + 1) : 0
    radius: Appearance.rounding.normal
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        id: loader

        active: GlobalStates.isOverviewOpen && (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name)
        asynchronous: true
        sourceComponent: GridLayout {
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
                }
            }
        }
    }
}
