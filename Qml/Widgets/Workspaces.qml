pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    required property ShellScreen monitor

    implicitWidth: (Configs.bar.workspacesIndicator === "dot" ? loader.item?.implicitWidth : loaderInteractiveWp.item?.implicitWidth) ?? 0 // qmllint disable
    implicitHeight: 30

    property real containerWidth: 60
    property real containerHeight: 30

    // Caelestia credit
    readonly property var toplevelsByWorkspace: {
        const acc = {};
        for (const tl of Hypr.toplevels.values ?? Hypr.toplevels) {
            const ws = Hypr.toplevelWorkspaceAddress(tl);
            if (!acc[ws])
                acc[ws] = [];
            acc[ws].push(tl);
        }
        return acc;
    }

    // Live hover target, 0 when the pointer is not on a dot.
    property int previewWorkspace: 0
    // Latched to the last hovered dot so the board keeps its content and its
    // size while its surface stays up after the pointer has left the dot.
    property int shownWorkspace: 0
    // Screen x of the hovered dot's left edge. The bar window is anchored to
    // the screen's top-left, so the dot's scene position is its screen position.
    property real previewDotX: 0

    readonly property var previewToplevels: root.toplevelsByWorkspace[root.shownWorkspace] ?? []

    Loader {
        id: loader

        anchors.fill: parent
        active: true
        sourceComponent: dotWorkspaceIndicator
    }

    WorkspacePreview {
        dotX: root.previewDotX
        toplevels: root.previewToplevels
        dotHovered: root.previewWorkspace > 0
    }

    Component {
        id: dotWorkspaceIndicator

        Row {
            id: container

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            // Caelestia credit
            readonly property var occupied: {
                const acc = {};
                for (const [ws, tls] of Object.entries(root.toplevelsByWorkspace))
                    acc[ws] = tls.find(tl => tl.activated) ?? tls[0];
                return acc;
            }
            property int focusedWorkspace: Hypr.activeWsId

            function iconForToplevel(toplevel: var): string {
                const windowClass = toplevel?.lastIpcObject?.class;
                const entry = windowClass ? DesktopEntries.heuristicLookup(windowClass) : null;
                return entry?.icon ? Quickshell.iconPath(entry.icon, "image-missing") : "";
            }

            readonly property int transitionDuration: Appearance.animations.durations.expressiveDefaultSpatial
            readonly property list<real> transitionCurve: Appearance.animations.curves.expressiveDefaultSpatial

            clip: true
            spacing: 0

            Repeater {
                model: {
                    const maxOccupied = Object.keys(container.occupied).reduce((max, id) => {
                        const n = parseInt(id, 10);
                        return isNaN(n) ? max : Math.max(max, n);
                    }, 0);
                    const minFromFocus = container.focusedWorkspace >= Configs.bar.visibleWorkspace ? container.focusedWorkspace : Configs.bar.visibleWorkspace;
                    return Math.max(Configs.bar.visibleWorkspace, minFromFocus, maxOccupied);
                }
                delegate: Item {
                    id: delegateRoot

                    required property int index
                    property int workspaceId: index + 1
                    property var toplevel: container.occupied[workspaceId] ?? null
                    property bool isActive: container.focusedWorkspace === workspaceId
                    property bool isOccupied: delegateRoot.toplevel !== null
                    property bool isEmpty: !isOccupied && !isActive

                    implicitHeight: parent.height
                    implicitWidth: isActive ? 40 : (height ? height : 1)

                    Behavior on implicitWidth {
                        NAnim {
                            duration: container.transitionDuration
                            easing.bezierCurve: container.transitionCurve
                        }
                    }

                    MArea {
                        visible: !delegateRoot.isActive
                        anchors.fill: parent
                        layerColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.8)
                        layerRadius: 5
                        onClicked: Workspaces.switchWorkspace(delegateRoot.workspaceId)
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                root.previewDotX = delegateRoot.mapToItem(null, 0, 0).x; // qmllint disable
                                root.shownWorkspace = delegateRoot.workspaceId;
                                root.previewWorkspace = delegateRoot.workspaceId;
                            } else if (root.previewWorkspace === delegateRoot.workspaceId) {
                                root.previewWorkspace = 0;
                            }
                        }
                    }

                    MaterialShape {
                        id: shapeIndicator
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }

                        shape: isEmpty ? MaterialShape.Circle : MaterialShape.Pill
                        animationDuration: container.transitionDuration
                        animationEasing.type: Easing.BezierSpline
                        animationEasing.bezierCurve: container.transitionCurve

                        state: isEmpty ? "empty" : (isActive ? "active" : (isOccupied ? "occupied" : "inactive"))

                        // qmllint disable
                        states: [
                            State {
                                name: "empty"
                                PropertyChanges {
                                    target: shapeIndicator
                                    width: 8
                                    height: 8
                                    opacity: 0.5
                                    color: Colours.m3Colors.m3OutlineVariant
                                }
                            },
                            State {
                                name: "active"
                                PropertyChanges {
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                    height: 20
                                    opacity: 1.0
                                    color: Colours.m3Colors.m3Primary
                                }
                            },
                            State {
                                name: "occupied"
                                PropertyChanges {
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                    height: 20
                                    opacity: 0.5
                                    color: Colours.m3Colors.m3PrimaryFixedDim
                                }
                            },
                            State {
                                name: "inactive"
                                PropertyChanges {
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                    height: 20
                                    opacity: 0.5
                                    color: Colours.m3Colors.m3OutlineVariant
                                }
                            }
                        ]
                        // qmllint enable

                        transitions: Transition {
                            NAnim {
                                properties: "width,height,opacity"
                                duration: container.transitionDuration
                                easing.bezierCurve: container.transitionCurve
                            }
                            CAnim {
                                duration: container.transitionDuration
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: Appearance.fonts.size.small
                            source: container.iconForToplevel(delegateRoot.toplevel)
                            visible: source !== ""
                            asynchronous: false
                            backer.cache: true
                        }
                    }
                }
            }
        }
    }
}
