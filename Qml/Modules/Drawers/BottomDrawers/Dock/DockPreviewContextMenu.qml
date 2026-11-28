pragma ComponentBehavior: Bound

import QtQuick
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
    readonly property bool isFloating: DockServices.isToplevelFloating(root.currentToplevel)
    readonly property bool isFullscreen: DockServices.isToplevelFullscreen(root.currentToplevel)

    property real          anchorX: 0
    property real          anchorY: 0
    property var           currentToplevel: null
    property bool          opened: false
    property ShellScreen   screen: null

    signal                 menuClosed
    signal                 windowFocused

    function               closeMenu(): void {
        if (!opened)
            return;
        opened          = false;
        currentToplevel = null;
        menuClosed();
    }

    function               openAt(x: real, y: real, toplevel: var): void {
        if (!toplevel)
            return;
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
            const screenHeight = root.screen ? root.screen.height : root.anchorY;
            const maxY         = Math.max(0, screenHeight - menuCard.implicitHeight);
            const preferredY   = root.anchorY + menuCard.implicitHeight <= screenHeight ? root.anchorY : (root.anchorY - menuCard.implicitHeight);

            return Math.max(0, Math.min(preferredY, maxY));
        }

        WlrLayershell.layer: WlrLayer.Overlay
        aboveWindows: true
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        screen: root.screen
        BackgroundEffect.blurRegion: Region {
            item: popupWindow.contentItem
        }
        HyprlandWindow.visibleMask: Region {
            item: popupWindow.contentItem
        }
        mask: Region {
            item: inputLayer
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.closeMenu()
        }

        Connections {

            function onClosed(): void {
                root.closeMenu();
            }

            target: root.currentToplevel?.wayland ?? null
        }

        Item {
            id: inputLayer

            anchors.fill: parent

            MouseArea {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent
                onClicked: root.closeMenu()
            }
        }

        Rectangle {
            id: menuCard

            color: GlobalStates.drawerColors
            implicitHeight: menuSurface.implicitHeight
            implicitWidth: root.cardWidth
            radius: Appearance.rounding.small
            x: popupWindow.cardX
            y: popupWindow.cardY

            MenuSurface {
                id: menuSurface

                anchors.fill: parent
                implicitWidth: root.cardWidth
                showScrollBar: false

                MenuItem {
                    label: qsTr("Focus")
                    onTriggered: {
                        if (root.currentToplevel)
                            DockServices.focusToplevel(root.currentToplevel);
                        root.closeMenu();
                        root.windowFocused();
                    }
                }

                MenuItem {
                    label: qsTr("Toggle Floating")
                    selected: root.isFloating
                    onTriggered: {
                        if (root.currentToplevel)
                            DockServices.toggleFloating(root.currentToplevel);
                        root.closeMenu();
                    }
                }

                MenuItem {
                    label: qsTr("Fullscreen")
                    selected: root.isFullscreen
                    onTriggered: {
                        if (root.currentToplevel)
                            DockServices.toggleFullscreen(root.currentToplevel);
                        root.closeMenu();
                    }
                }

                MenuDivider {}

                MenuItem {
                    label: qsTr("Close")
                    onTriggered: {
                        if (root.currentToplevel)
                            DockServices.closeToplevel(root.currentToplevel);
                        root.closeMenu();
                    }
                }
            }
        }
    }
}
