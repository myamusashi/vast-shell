pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: root

    implicitWidth: loader.item.implicitWidth
    implicitHeight: 30

    property real workspaceWidth: Hypr.focusedMonitor.width - (reserved[0] + reserved[2])
    property real workspaceHeight: Hypr.focusedMonitor.height - (reserved[1] + reserved[3])
    property real containerWidth: 60
    property real containerHeight: 30
    property list<int> reserved: Hypr.focusedMonitor.lastIpcObject.reserved
    property real scaleFactor: Math.min(containerWidth / workspaceWidth, containerHeight / workspaceHeight)
    property real borderWidth: 2

    MArea {
        id: workspaceMBarArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        propagateComposedEvents: true
        onClicked: mouse => {
            let loaderPos = mapToItem(loader, mouse.x, mouse.y);
            if (loader.contains(Qt.point(loaderPos.x, loaderPos.y))) {
                mouse.accepted = false;
                return;
            }

            Quickshell.execDetached({
                "command": ["sh", "-c", "hyprctl dispatch global quickshell:overview"]
            });
        }
    }

    Loader {
        id: loader

        anchors.fill: parent
        asynchronous: true
        active: true

        sourceComponent: Configs.bar.workspacesIndicator === "dot" ? dotWorkspaceIndicator : interactiveWorkspaceIndicator
    }

    Component {
        id: dotWorkspaceIndicator

        RowLayout {
            id: container

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            property int focusedWorkspace: Hypr.activeWsId
            readonly property var occupied: Hypr.workspaces.values.reduce((acc, curr) => { // Caelestia credit
                acc[curr.id] = curr.lastIpcObject.windows > 0;
                return acc;
            }, {})

            clip: true
            spacing: 0
            Repeater {
                model: Math.max(Configs.bar.visibleWorkspace, container.focusedWorkspace >= Configs.bar.visibleWorkspace ? container.focusedWorkspace + 1 : Configs.bar.visibleWorkspace)
                delegate: Item {
                    id: delegateRoot

                    required property int index
                    property int workspaceId: index + 1
                    property bool isActive: container.focusedWorkspace === workspaceId
                    property bool isOccupied: container.occupied[workspaceId] === true
                    property bool isEmpty: !isOccupied && !isActive

                    implicitHeight: parent.height
                    implicitWidth: height ? height : 1

                    Behavior on implicitWidth {
                        NAnim {
                            duration: Appearance.animations.durations.emphasized
                            easing.bezierCurve: Appearance.animations.curves.emphasized
                        }
                    }

                    MArea {
                        visible: !delegateRoot.isActive
                        anchors.fill: parent
                        layerColor: Colours.withAlpha(Colours.m3Colors.m3Primary, 0.8)
                        layerRadius: 5
                        onClicked: Hyprland.dispatch("workspace " + delegateRoot.workspaceId)
                    }

                    StyledRect {
                        id: fgIndicator

                        anchors.centerIn: parent
                        implicitWidth: delegateRoot.isActive ? 24 : 8
                        implicitHeight: 8
                        radius: Appearance.rounding.small
                        color: {
                            if (delegateRoot.isActive)
                                return Colours.m3Colors.m3Primary;
                            else if (delegateRoot.isOccupied)
                                return Colours.m3Colors.m3OutlineVariant;
                            else
                                return Colours.m3Colors.m3OnPrimary;
                        }
                        opacity: delegateRoot.isActive ? 1.0 : 0.5

                        Behavior on implicitWidth {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                        Behavior on opacity {
                            NAnim {
                                duration: Appearance.animations.durations.emphasized
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: interactiveWorkspaceIndicator

        Row {
            id: workspaceRow

            anchors.centerIn: parent
            spacing: Appearance.spacing.small

            Repeater {
                model: Workspaces.maxWorkspace + 1

                delegate: StyledRect {
                    id: workspaceContainer

                    width: root.containerWidth
                    height: root.containerHeight
                    color: workspace?.focused ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                    radius: 0
                    clip: true
                    required property int index
                    property HyprlandWorkspace workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) ?? null
                    property bool hasFullscreen: !!(workspace?.toplevels?.values.some(t => t.wayland?.fullscreen))
                    property bool hasMaximized: !!(workspace?.toplevels?.values.some(t => t.wayland?.maximized))

                    DropArea {
                        anchors.fill: parent

                        onEntered: drag => drag.source.isCaught = true
                        onExited: drag.source.isCaught = false

                        onDropped: drag => {
                            const toplevel = drag.source;

                            if (toplevel.modelData.workspace !== workspaceContainer.workspace) {
                                const address = toplevel.modelData.address;
                                Hypr.dispatch(`movetoworkspacesilent ${workspaceContainer.index + 1}, address:0x${address}`);
                                Hypr.dispatch(`movewindowpixel exact ${toplevel.initX} ${toplevel.initY}, address:0x${address}`);
                            }
                        }
                    }

                    MArea {
                        anchors.fill: parent
                        onClicked: {
                            if (workspaceContainer.workspace !== Hyprland.focusedWorkspace)
                                Hypr.dispatch("workspace " + (parent.index + 1));
                        }
                    }

                    Repeater {
                        model: workspaceContainer.workspace?.toplevels

                        delegate: ScreencopyView {
                            id: toplevel

                            required property HyprlandToplevel modelData
                            property Toplevel waylandHandle: modelData?.wayland
                            property var toplevelData: modelData.lastIpcObject
                            property int initX: toplevelData.at[0] ?? 0
                            property int initY: toplevelData.at[1] ?? 0
                            property StyledRect originalParent: workspaceContainer
                            property StyledRect visualParent: root
                            property bool isCaught: false

                            captureSource: waylandHandle
                            live: false

                            width: sourceSize.width * root.scaleFactor / Hypr.focusedMonitor.scale
                            height: sourceSize.height * root.scaleFactor / Hypr.focusedMonitor.scale
                            scale: (Drag.active && !toplevelData?.floating) ? 0.98 : 1

                            Rectangle {
                                anchors.fill: parent
                                color: toplevel.modelData.activated ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnPrimary
                                border.color: toplevel.modelData.activated ? Colours.m3Colors.m3Outline : Colours.m3Colors.m3OutlineVariant
                                border.width: 1
                            }

                            x: (toplevelData?.at[0] - (waylandHandle?.fullscreen ? 0 : root.reserved[0])) * root.scaleFactor + (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2
                            y: (toplevelData?.at[1] - (waylandHandle?.fullscreen ? 0 : root.reserved[1])) * root.scaleFactor + (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2
                            z: (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 2 : toplevelData?.floating ? 1 : 0

                            Drag.active: mouseArea.drag.active
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.onActiveChanged: {
                                if (Drag.active)
                                    parent = visualParent;
                                else {
                                    var mapped = mapToItem(originalParent, 0, 0);
                                    parent = originalParent;

                                    if (toplevelData?.floating) {
                                        x = mapped.x;
                                        y = mapped.y;
                                    } else if (!isCaught) {
                                        x = mapped.x;
                                        y = mapped.y;
                                    } else {
                                        const baseX = toplevelData?.at[0] ?? 0;
                                        const baseY = toplevelData?.at[1] ?? 0;
                                        const offsetX = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[0];
                                        const offsetY = (waylandHandle?.fullscreen || waylandHandle?.maximized) ? 0 : root.reserved[1];
                                        x = (baseX - offsetX) * root.scaleFactor + (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2;
                                        y = (baseY - offsetY) * root.scaleFactor + (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2;
                                    }
                                }
                            }

                            MArea {
                                id: mouseArea

                                anchors.fill: parent

                                property bool dragged: false

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
                                        const mapped = toplevel.mapToItem(toplevel.originalParent, 0, 0);
                                        const centerOffsetX = (root.containerWidth - root.workspaceWidth * root.scaleFactor) / 2;
                                        const centerOffsetY = (root.containerHeight - root.workspaceHeight * root.scaleFactor) / 2;
                                        const x = Math.round((mapped.x - centerOffsetX) / root.scaleFactor + root.reserved[0]);
                                        const y = Math.round((mapped.y - centerOffsetY) / root.scaleFactor + root.reserved[1]);

                                        Hypr.dispatch(`movewindowpixel exact ${x} ${y}, address:0x${toplevel.modelData.address}`);
                                        toplevel.Drag.drop();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
