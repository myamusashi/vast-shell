pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Components.Menu
import qs.Core.Configs
import qs.Core.States
import qs.Services

LazyLoader {
    id: root

    readonly property real cardWidth: 220

    property real          anchorX: 0
    property real          anchorY: 0
    property var           currentEntry: null
    property var           currentToplevel: null
    property bool          opened: false
    property ShellScreen   screen: null

    function               closeMenu(): void {
        opened = false;
    }
    function               openAt(x: real, y: real, entry: var, toplevel: var): void {
        currentEntry    = entry;
        currentToplevel = toplevel;
        anchorX         = x;
        anchorY         = y;
        opened          = true;
    }

    activeAsync: opened
    component: PanelWindow {
        id: popupWindow

        readonly property real cardX: Math.max(0, Math.min(root.anchorX, (root.screen ? root.screen.width : root.anchorX) - root.cardWidth))
        readonly property real cardY: {
            const maxY = (root.screen ? root.screen.height : root.anchorY) - menuCard.implicitHeight;

            return Math.max(0, Math.min(root.anchorY - menuCard.implicitHeight - Appearance.spacing.small, maxY));
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        screen: root.screen
        color: "transparent"
        aboveWindows: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        // qmllint disable
        HyprlandWindow.visibleMask: Region {
            item: menuCard
        }
        // qmllint enable
        mask: Region {
            item: inputLayer
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.closeMenu()
        }

        Item {
            id: inputLayer
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: root.closeMenu()
            }
        }

        Rectangle {
            id: menuCard
            x: popupWindow.cardX
            y: popupWindow.cardY
            color: GlobalStates.drawerColors
            implicitHeight: menuSurface.implicitHeight
            implicitWidth: root.cardWidth
            radius: Appearance.rounding.small

            MenuSurface {
                id: menuSurface
                anchors.fill: parent
                implicitWidth: root.cardWidth
                showScrollBar: false

                MenuItem {
                    label: qsTr("Open")
                    onTriggered: {
                        DockServices.activatePinned(root.currentEntry);
                        root.closeMenu();
                    }
                }

                MenuItem {
                    label: qsTr("New Window")
                    onTriggered: {
                        DockServices.launchEntry(root.currentEntry);
                        root.closeMenu();
                    }
                }

                MenuItem {
                    label: DockServices.pinnedIds.includes(root.currentEntry ? root.currentEntry.id : "") ? qsTr("Unpin from Dock") : qsTr("Pin to Dock")
                    onTriggered: {
                        if (root.currentEntry)
                            DockServices.togglePin(root.currentEntry.id);
                        root.closeMenu();
                    }
                }

                MenuItem {
                    label: qsTr("Close")
                    visible: root.currentToplevel !== null
                    onTriggered: {
                        if (root.currentToplevel)
                            root.currentToplevel.wayland.close();
                        root.closeMenu();
                    }
                }

                MenuItem {
                    label: qsTr("Close All Windows")
                    visible: root.currentEntry !== null && DockServices.runningEntryIds.includes(root.currentEntry.id)
                    onTriggered: {
                        if (root.currentEntry)
                            DockServices.closeAllWindows(root.currentEntry.id);
                        root.closeMenu();
                    }
                }
            }
        }
    }
}
