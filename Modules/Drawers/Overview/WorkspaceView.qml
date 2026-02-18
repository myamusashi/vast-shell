pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
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
    property real monitorLogicalWidth: (wsp?.monitor) ? (wsp.monitor.width / wsp.monitor.scale) : 1
    property real monitorLogicalHeight: (wsp?.monitor) ? (wsp.monitor.height / wsp.monitor.scale) : 1
    property real monitorLogicalX: (wsp?.monitor) ? (wsp.monitor.x / wsp.monitor.scale) : 0
    property real monitorLogicalY: (wsp?.monitor) ? (wsp.monitor.y / wsp.monitor.scale) : 0
    property real scaleFactor: (wsp?.monitor) ? (monitorLogicalWidth / implicitWidth) : -1

    border {
        width: 2
        color: wsp?.focused ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3OnPrimary, 0.5)
    }
    color: "transparent"
    radius: Appearance.rounding.small

    Connections {
        target: root.wsp ? root.wsp.toplevels : null

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

    StyledText {
        anchors.centerIn: parent
        text: root.index + 1
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.normal
    }

    DropArea {
        anchors.fill: parent
        onEntered: drag => drag.source.isCaught = true
        onExited: drag.source.isCaught = false
        onDropped: drag => {
            const toplevel = drag.source;
            if (toplevel.modelData.workspace !== root.wsp) {
                const address = toplevel.modelData.address;
                Hypr.dispatch(`movetoworkspacesilent ${root.index + 1}, address:0x${address}`);
                Hypr.dispatch(`movewindowpixel exact ${toplevel.initX} ${toplevel.initY}, address:0x${address}`);
            }

            Hyprland.refreshWorkspaces();
            Hyprland.refreshMonitors();
            Hyprland.refreshToplevels();
        }
    }

    MArea {
        anchors.fill: parent
        onClicked: {
            if (root.wsp !== Hypr.focusedWorkspace)
                Hypr.dispatch("workspace " + (root.index + 1));
        }
    }

    Loader {
        anchors.fill: parent
        active: GlobalStates.isOverviewOpen
        sourceComponent: Image {
            source: Paths.currentWallpaper
            sourceSize: Qt.size(root.width, root.height)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }

    Repeater {
        id: repeater

        model: root.wsp ? root.wsp.toplevels : []

        ScreencopyView {
            id: toplevel

            required property HyprlandToplevel modelData

            property Toplevel waylandHandle: modelData?.wayland
            property var toplevelData: modelData.lastIpcObject
            property string address: toplevelData.address ?? null
            property int initX: toplevelData.at[0] ?? 0
            property int initY: toplevelData.at[1] ?? 0
            property bool isCaught: false
            property Item originalParent: root
            property Item visualParent: root.parentWindow

            // Logical position relative to this tile
            property real baseX: (toplevelData?.at[0] ?? 0) - root.monitorLogicalX
            property real baseY: (toplevelData?.at[1] ?? 0) - root.monitorLogicalY

            captureSource: waylandHandle
            live: true
            width: (toplevelData?.size?.[0] ?? 0) / root.scaleFactor
            height: (toplevelData?.size?.[1] ?? 0) / root.scaleFactor
            scale: (Drag.active && !toplevelData?.floating) ? 0.92 : 1
            opacity: GlobalStates.isOverviewOpen ? 1 : 0
            z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : (toplevelData?.floating) ? 1 : 0
            x: baseX / root.scaleFactor
            y: baseY / root.scaleFactor
            Component.onCompleted: Hyprland.refreshToplevels()

            Behavior on scale {
                NAnim {}
            }
            Behavior on opacity {
                NAnim {}
            }

            Drag.active: mouseArea.drag.active
            Drag.source: toplevel
            Drag.supportedActions: Qt.MoveAction
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.onActiveChanged: {
                if (Drag.active) {
                    parent = visualParent;
                } else {
                    const mapped = mapToItem(originalParent, 0, 0);
                    parent = originalParent;

                    if (toplevelData?.floating) {
                        x = mapped.x;
                        y = mapped.y;
                    } else {
                        x = !isCaught ? mapped.x : baseX / root.scaleFactor;
                        y = !isCaught ? mapped.y : baseY / root.scaleFactor;
                    }
                }

                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
                Hyprland.refreshToplevels();
            }

            IconImage {
                anchors.centerIn: parent
                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(toplevel.waylandHandle?.appId)?.icon, "image-missing")
                asynchronous: true
                width: 25
                height: 25
                backer.cache: true
                backer.asynchronous: true
            }

            MArea {
                id: mouseArea

                anchors.fill: parent

                property bool dragged: false

                // Prevent dragging fullscreen / maximized windows
                drag.target: (toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized) ? undefined : toplevel
                cursorShape: dragged ? Qt.DragMoveCursor : Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: dragged = false
                onPositionChanged: {
                    if (drag.active)
                        dragged = true;
                }
                onClicked: mouse => {
                    if (!dragged) {
                        if (mouse.button === Qt.LeftButton)
                            toplevel.waylandHandle.activate();
                        else if (mouse.button === Qt.RightButton)
                            toplevel.waylandHandle.close();
                    }
                }
                onReleased: {
                    if (dragged && !(toplevel.waylandHandle?.fullscreen || toplevel.waylandHandle?.maximized)) {
                        if (toplevel.toplevelData?.floating) {
                            const mapped = toplevel.mapToItem(toplevel.originalParent, 0, 0);
                            const globalX = Math.round(mapped.x * root.scaleFactor + root.monitorLogicalX);
                            const globalY = Math.round(mapped.y * root.scaleFactor + root.monitorLogicalY);
                            Hypr.dispatch(`movewindowpixel exact ${globalX} ${globalY}, address:${toplevel.address}`);
                        }
                        toplevel.Drag.drop();
                    }

                    Hyprland.refreshWorkspaces();
                    Hyprland.refreshMonitors();
                    Hyprland.refreshToplevels();
                }
            }
        }
    }
}
