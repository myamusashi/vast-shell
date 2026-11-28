pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    required property ShellScreen monitor

    readonly property list<real>  effectsCurve: Appearance.animations.curves.expressiveEffects
    readonly property int         effectsDuration: Appearance.animations.durations.expressiveEffects
    readonly property string      focusedToplevelAddress: {
        if (Hypr.activeToplevel?.address)
            return Hypr.activeToplevel.address;
        if (GlobalStates.isShellKeyboardGrabActive)
            return Hypr.lastActiveToplevelAddress;
        return "";
    }
    readonly property int         focusedWorkspace: Hypr.activeWsId
    readonly property real        iconSize: 11
    readonly property real        iconSpacing: 3
    readonly property var         previewToplevels: root.toplevelsByWorkspace[root.shownWorkspace] ?? []
    // Caelestia credit
    readonly property var         toplevelsByWorkspace: Hypr.toplevelsByWorkspace
    readonly property list<real>  transitionCurve: Appearance.animations.curves.expressiveDefaultSpatial
    readonly property int         transitionDuration: Appearance.animations.durations.expressiveDefaultSpatial
    readonly property real        unfocusedIconOpacity: 0.45
    readonly property var         workspaceToplevels: {
        const result = {};
        for (const [workspaceKey, list] of Object.entries(root.toplevelsByWorkspace)) {
            if (list && list.length > 0)
                result[workspaceKey] = [...list].sort((first, second) => root.compareToplevelAddress(first, second));
        }
        return result;
    }

    property real                 containerHeight: 22
    property real                 containerWidth: 44
    // Screen x of the hovered dot's left edge. The bar window is anchored to
    // the screen's top-left, so the dot's scene position is its screen position.
    property real                 previewDotX: 0
    // Live hover target, 0 when the pointer is not on a dot.
    property int                  previewWorkspace: 0
    // Latched to the last hovered dot so the board keeps its content and its
    // size while its surface stays up after the pointer has left the dot.
    property int                  shownWorkspace: 0

    function                      compareToplevelAddress(first: var, second: var): int {
        const firstKey  = parseInt(first?.address ?? "", 16);
        const secondKey = parseInt(second?.address ?? "", 16);
        if (!isNaN(firstKey) && !isNaN(secondKey) && firstKey !== secondKey)
            return firstKey < secondKey ? -1 : 1;
        return String(first?.address ?? "").localeCompare(String(second?.address ?? ""));
    }

    function                      iconForToplevel(toplevel: var): string {
        const windowClass = toplevel?.lastIpcObject?.class;
        if (!windowClass)
            return "";

        const entry = DesktopEntries.heuristicLookup(windowClass);
        if (!entry?.icon)
            return "";

        return Quickshell.iconPath(entry.icon, true);
    }

    implicitHeight: 22
    implicitWidth: container.implicitWidth

    WorkspacePreview {
        dotHovered: root.previewWorkspace > 0
        dotX: root.previewDotX
        monitor: root.monitor
        toplevels: root.previewToplevels
    }

    Row {
        id: container

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        clip: true
        height: parent.height
        spacing: 0

        Repeater {
            model: {
                const maxOccupied  = Object.keys(root.workspaceToplevels).reduce((max, id) => {
                    const parsed = parseInt(id, 10);
                    return isNaN(parsed) ? max : Math.max(max, parsed);
                }, 0);
                const minFromFocus = root.focusedWorkspace >= Configs.bar.visibleWorkspace ? root.focusedWorkspace : Configs.bar.visibleWorkspace;
                return Math.max(Configs.bar.visibleWorkspace, minFromFocus, maxOccupied);
            }
            delegate: Item {
                id: delegateRoot

                required property int  index

                readonly property bool isActive: root.focusedWorkspace === delegateRoot.workspaceId
                readonly property bool isEmpty: !delegateRoot.isOccupied && !delegateRoot.isActive
                readonly property bool isOccupied: delegateRoot.toplevels.length > 0
                readonly property real pillWidth: {
                    if (delegateRoot.isEmpty)
                        return 6;
                    if (delegateRoot.isActive)
                        return Math.max(24, iconRow.implicitWidth + 12);
                    return iconRow.implicitWidth > root.iconSize ? iconRow.implicitWidth + 8 : 16;
                }
                readonly property var  primaryToplevel: (root.toplevelsByWorkspace[delegateRoot.workspaceId] ?? [])[0] ?? null
                readonly property var  toplevels: root.workspaceToplevels[delegateRoot.workspaceId] ?? []
                readonly property int  workspaceId: index + 1

                implicitHeight: parent.height
                implicitWidth: Math.max(delegateRoot.isActive ? 26 : 18, delegateRoot.pillWidth + 2)
                Behavior on implicitWidth {
                    NAnim {
                        duration: root.transitionDuration
                        easing.bezierCurve: root.transitionCurve
                    }
                }

                MArea {
                    anchors.fill: parent
                    layerColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.8)
                    layerRadius: 6
                    visible: !delegateRoot.isActive
                    onClicked: Workspaces.focusToplevel(delegateRoot.workspaceId, delegateRoot.primaryToplevel?.address ?? "")
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

                StyledRect {
                    id: shapeIndicator

                    anchors.centerIn: parent
                    color: delegateRoot.isEmpty ? Colours.m3Colors.m3OutlineVariant : (delegateRoot.isActive ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3PrimaryFixedDim)
                    height: delegateRoot.isEmpty ? 6 : 16
                    opacity: delegateRoot.isActive ? 1.0 : 0.5
                    radius: height / 2
                    width: delegateRoot.pillWidth
                    Behavior on color {
                        CAnim {
                            duration: root.transitionDuration
                        }
                    }
                    Behavior on height {
                        NAnim {
                            duration: root.transitionDuration
                            easing.bezierCurve: root.transitionCurve
                        }
                    }
                    Behavior on opacity {
                        NAnim {
                            duration: root.transitionDuration
                            easing.bezierCurve: root.transitionCurve
                        }
                    }
                    Behavior on width {
                        NAnim {
                            duration: root.transitionDuration
                            easing.bezierCurve: root.transitionCurve
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    clip: true
                    height: shapeIndicator.height
                    width: shapeIndicator.width

                    Row {
                        id: iconRow

                        anchors.centerIn: parent
                        spacing: root.iconSpacing
                        visible: delegateRoot.isOccupied

                        Repeater {
                            model: ScriptModel {
                                objectProp: "address"
                                values: delegateRoot.toplevels
                            }
                            delegate: Item {
                                id: toplevelDelegate

                                required property var    modelData

                                readonly property string iconSource: root.iconForToplevel(toplevelDelegate.modelData)
                                readonly property bool   isFocused: toplevelDelegate.modelData !== null && toplevelDelegate.modelData !== undefined && (toplevelDelegate.modelData.wayland?.activated === true || (root.focusedToplevelAddress !== "" && toplevelDelegate.modelData.address === root.focusedToplevelAddress))

                                implicitHeight: 16
                                implicitWidth: root.iconSize
                                visible: toplevelDelegate.iconSource !== ""

                                IconImage {
                                    anchors.centerIn: parent
                                    asynchronous: false
                                    backer.cache: true
                                    implicitSize: root.iconSize
                                    opacity: toplevelDelegate.isFocused ? 1.0 : root.unfocusedIconOpacity
                                    source: toplevelDelegate.iconSource
                                    Behavior on opacity {
                                        NAnim {
                                            duration: root.effectsDuration
                                            easing.bezierCurve: root.effectsCurve
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: toplevelDelegate.isFocused ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !toplevelDelegate.isFocused
                                    hoverEnabled: true
                                    onClicked: Workspaces.focusToplevel(delegateRoot.workspaceId, toplevelDelegate.modelData?.address ?? "")
                                }
                            }
                        }
                    }
                }

                Tooltip {
                    anchorItem: delegateRoot
                    enabled: !delegateRoot.isOccupied
                    text: delegateRoot.isActive ? qsTr("Workspace %1 (Active)").arg(delegateRoot.workspaceId) : qsTr("Workspace %1 · Empty").arg(delegateRoot.workspaceId)
                }
            }
        }
    }
}
