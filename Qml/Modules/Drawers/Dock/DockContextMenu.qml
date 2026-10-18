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

    property real        clickX: 0
    property real        clickY: 0
    property var         currentEntry: null
    property var         currentToplevel: null
    property real        menuX: 0
    property real        menuY: 0
    property bool        opened: false
    property ShellScreen screen: null

    function             closeMenu(): void {
        root.opened = false;
    }
    function             openAt(x: real, y: real, entry: var, toplevel: var): void {
        root.currentEntry    = entry;
        root.currentToplevel = toplevel;
        root.clickX          = x;
        root.clickY          = y;
        root.menuX           = Math.max(0, Math.min(x, (root.screen ? root.screen.width : x) - 220));
        root.menuY           = Math.max(0, y - 240);
        root.opened          = true;
    }

    activeAsync: opened
    component: PanelWindow {
        id: popupWindow

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
            x: root.menuX
            y: root.menuY
            color: GlobalStates.drawerColors
            implicitHeight: menuSurface.implicitHeight
            implicitWidth: 220
            radius: Appearance.rounding.small

            MenuSurface {
                id: menuSurface
                anchors.fill: parent
                implicitWidth: 220
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
                    label: DockServices.isPinned(root.currentEntry ? root.currentEntry.id : "") ? qsTr("Unpin from Dock") : qsTr("Pin to Dock")
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
