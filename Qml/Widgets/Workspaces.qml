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

    property real                 containerHeight: 30
    property real                 containerWidth: 60
    // Screen x of the hovered dot's left edge. The bar window is anchored to
    // the screen's top-left, so the dot's scene position is its screen position.
    readonly property var         previewToplevels: root.toplevelsByWorkspace[root.shownWorkspace] ?? []

    property real                 previewDotX: 0

    // Live hover target, 0 when the pointer is not on a dot.
    property int                  previewWorkspace: 0
    // Latched to the last hovered dot so the board keeps its content and its
    // size while its surface stays up after the pointer has left the dot.
    property int                  shownWorkspace: 0

    // Caelestia credit
    readonly property var         toplevelsByWorkspace: Hypr.toplevelsByWorkspace

    implicitHeight: 30
    implicitWidth: loader.item?.implicitWidth ?? 0 // qmllint disable

    Loader {
        id: loader

        active: true
        anchors.fill: parent
        sourceComponent: dotWorkspaceIndicator
    }

    WorkspacePreview {
        dotHovered: root.previewWorkspace > 0
        dotX: root.previewDotX
        toplevels: root.previewToplevels
    }

    Component {
        id: dotWorkspaceIndicator

        Row {
            id: container

            property int                 focusedWorkspace: Hypr.activeWsId

            // Caelestia credit
            readonly property var        occupied: {
                const acc = {};
                for (const [ws, tls] of Object.entries(root.toplevelsByWorkspace))
                    acc[ws] = tls[0] ?? null;
                return acc;
            }
            readonly property list<real> transitionCurve: Appearance.animations.curves.expressiveDefaultSpatial
            readonly property int        transitionDuration: Appearance.animations.durations.expressiveDefaultSpatial

            function                     iconForToplevel(toplevel: var): string {
                const windowClass = toplevel?.lastIpcObject?.class;
                const entry       = windowClass ? DesktopEntries.heuristicLookup(windowClass) : null;
                return entry?.icon ? Quickshell.iconPath(entry.icon, "image-missing") : "";
            }

            clip: true
            spacing: 0

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }

            Repeater {
                model: {
                    const maxOccupied  = Object.keys(container.occupied).reduce((max, id) => {
                        const n = parseInt(id, 10);
                        return isNaN(n) ? max : Math.max(max, n);
                    }, 0);
                    const minFromFocus = container.focusedWorkspace >= Configs.bar.visibleWorkspace ? container.focusedWorkspace : Configs.bar.visibleWorkspace;
                    return Math.max(Configs.bar.visibleWorkspace, minFromFocus, maxOccupied);
                }
                delegate: Item {
                    id: delegateRoot

                    required property int index

                    property bool         isActive: container.focusedWorkspace === workspaceId
                    property bool         isEmpty: !isOccupied && !isActive
                    property bool         isOccupied: delegateRoot.toplevel !== null
                    property var          toplevel: container.occupied[workspaceId] ?? null
                    property int          workspaceId: index + 1

                    implicitHeight: parent.height
                    implicitWidth: isActive ? 40 : (height ? height : 1)
                    Behavior on implicitWidth {
                        NAnim {
                            duration: container.transitionDuration
                            easing.bezierCurve: container.transitionCurve
                        }
                    }

                    MArea {
                        anchors.fill: parent
                        layerColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.8)
                        layerRadius: 5
                        visible: !delegateRoot.isActive
                        onClicked: Workspaces.focusToplevel(delegateRoot.workspaceId, delegateRoot.toplevel?.address ?? "")
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered) {
                                root.previewDotX      = delegateRoot.mapToItem(null, 0, 0).x; // qmllint disable
                                root.shownWorkspace   = delegateRoot.workspaceId;
                                root.previewWorkspace = delegateRoot.workspaceId;
                            } else if (root.previewWorkspace === delegateRoot.workspaceId) {
                                root.previewWorkspace = 0;
                            }
                        }
                    }

                    MaterialShape {
                        id: shapeIndicator

                        animationDuration: container.transitionDuration
                        animationEasing.bezierCurve: container.transitionCurve
                        animationEasing.type: Easing.BezierSpline
                        shape: isEmpty ? MaterialShape.Circle : MaterialShape.Pill
                        state: isEmpty ? "empty" : (isActive ? "active" : (isOccupied ? "occupied" : "inactive"))

                        // qmllint disable
                        states: [
                            State {
                                name: "empty"

                                PropertyChanges {
                                    color: Colours.m3Colors.m3OutlineVariant
                                    height: 8
                                    opacity: 0.5
                                    target: shapeIndicator
                                    width: 8
                                }
                            },
                            State {
                                name: "active"

                                PropertyChanges {
                                    color: Colours.m3Colors.m3Primary
                                    height: 20
                                    opacity: 1.0
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                }
                            },
                            State {
                                name: "occupied"

                                PropertyChanges {
                                    color: Colours.m3Colors.m3PrimaryFixedDim
                                    height: 20
                                    opacity: 0.5
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                }
                            },
                            State {
                                name: "inactive"

                                PropertyChanges {
                                    color: Colours.m3Colors.m3OutlineVariant
                                    height: 20
                                    opacity: 0.5
                                    target: shapeIndicator
                                    width: Appearance.fonts.size.extraLarge
                                }
                            }
                        ]
                        // qmllint enable

                        transitions: Transition {

                            NAnim {
                                duration: container.transitionDuration
                                easing.bezierCurve: container.transitionCurve
                                properties: "width,height,opacity"
                            }

                            CAnim {
                                duration: container.transitionDuration
                            }
                        }

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }

                        IconImage {
                            anchors.centerIn: parent
                            asynchronous: false
                            backer.cache: true
                            implicitSize: Appearance.fonts.size.small
                            source: container.iconForToplevel(delegateRoot.toplevel)
                            visible: source !== ""
                        }
                    }
                }
            }
        }
    }
}
