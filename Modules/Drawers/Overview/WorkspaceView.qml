pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ClippingRectangle {
    id: root

    required property int index
    required property Item parentWindow

    property HyprlandWorkspace wsp: Hyprland.workspaces.values.find(s => s.id == (index + 1)) || null
    // Use logical monitor width (physical px ÷ scale) for the scale factor
    property real monitorLogicalWidth: (wsp?.monitor) ? (wsp.monitor.width / wsp.monitor.scale) : 1
    property real monitorLogicalHeight: (wsp?.monitor) ? (wsp.monitor.height / wsp.monitor.scale) : 1
    // Monitor origin in logical coordinates
    property real monitorLogicalX: (wsp?.monitor) ? (wsp.monitor.x / wsp.monitor.scale) : 0
    property real monitorLogicalY: (wsp?.monitor) ? (wsp.monitor.y / wsp.monitor.scale) : 0
    property real scaleFactor: (wsp?.monitor) ? (monitorLogicalWidth / implicitWidth) : -1

    border {
        width: 2
        color: Colours.m3Colors.m3SurfaceContainerHighest
    }
    color: "transparent"
    radius: Appearance.rounding.small

    Connections {
        target: (root.wsp) ? root.wsp?.toplevels : null

        function onObjectInsertedPost() {
            Hyprland.refreshToplevels();
        }
        function onObjectRemovedPre() {
            Hyprland.refreshToplevels();
        }
        function onObjectRemovedPost() {
            Hyprland.refreshToplevels();
        }
        function onObjectInsertedPre() {
            Hyprland.refreshToplevels();
        }
    }

    Loader {
        anchors.fill: parent
        active: GlobalStates.isOverviewOpen
        visible: active
        sourceComponent: Image {
            source: Paths.currentWallpaper
            sourceSize: Qt.size(root.width, root.height)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: root.index + 1
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.normal
    }

    MArea {
        anchors.fill: parent
        onClicked: {
            if (root.wsp !== Hypr.focusedWorkspace)
                Hypr.dispatch("workspace " + (root.index + 1));
        }
    }

    Repeater {
        model: (root.wsp) ? root.wsp.toplevels : []

        ScreencopyView {
            id: scView

            required property HyprlandToplevel modelData
            property string address: modelData.lastIpcObject.address ?? null

            captureSource: modelData?.wayland
            live: true

            // Hyprland reports window at[] in logical global coords.
            // Subtract the monitor's logical origin so positions are
            // relative to this workspace tile, then divide by scaleFactor.
            x: (modelData.lastIpcObject.at && root.wsp?.monitor) ? ((modelData.lastIpcObject.at[0] - root.monitorLogicalX) / root.scaleFactor) : 0
            y: (modelData.lastIpcObject.at && root.wsp?.monitor) ? ((modelData.lastIpcObject.at[1] - root.monitorLogicalY) / root.scaleFactor) : 0
            width: (modelData.lastIpcObject.size && root.wsp) ? (modelData.lastIpcObject.size[0] / root.scaleFactor) : 0
            height: (modelData.lastIpcObject.size && root.wsp) ? (modelData.lastIpcObject.size[1] / root.scaleFactor) : 0

            Component.onCompleted: Hyprland.refreshToplevels()

            DragHandler {
                id: dragHandler

                target: scView
                onActiveChanged: {
                    if (!active)
                        target.Drag.drop();
                }
            }

            Drag.active: dragHandler.active
            Drag.source: scView
            Drag.supportedActions: Qt.MoveAction
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2

            MArea {
                anchors.fill: parent

                onClicked: {
                    if (root.wsp !== Hypr.focusedWorkspace)
                        Hypr.dispatch("workspace " + (root.index + 1));
                }
            }

            states: [
                State {
                    when: dragHandler.active
                    ParentChange {
                        target: scView
                        parent: root.parentWindow
                    }
                }
            ]
        }
    }
}
