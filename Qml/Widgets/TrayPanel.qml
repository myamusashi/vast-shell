pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs

LazyLoader {
    id: root

    required property var trayRoot

    property Timer        closeTimer
    property Timer        hideTimer

    loading: true
    component: PanelWindow {
        HyprlandWindow.visibleMask: mask // qmllint disable
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "shell:drawers"
        aboveWindows: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        mask: Region {
            item: root.trayRoot.menuMapped ? menuSurface : null
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        margins { // qmllint disable
            right: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
        }

        Connections {
            function onActiveMenuChanged(): void {
                if (root.trayRoot.activeMenu !== null)
                    Qt.callLater(() => menuSurface.openMenu(root.trayRoot.activeMenu)); // qmllint disable
            }

            target: root.trayRoot
        }

        Item {
            id: panelroot

            anchors.fill: parent

            Item {
                id: menuHost

                readonly property real maxX: panelroot.width - menuSurface.width - root.trayRoot.shadowPadding
                readonly property real maxY: panelroot.height - menuSurface.height - root.trayRoot.shadowPadding

                height: menuSurface.height + root.trayRoot.shadowPadding * 2
                width: menuSurface.width + root.trayRoot.shadowPadding * 2
                x: Math.max(root.trayRoot.shadowPadding, Math.min(root.trayRoot.menuX - root.trayRoot.shadowPadding - menuSurface.bodyInsetX, maxX))
                y: Math.min(root.trayRoot.barBottom - root.trayRoot.shadowPadding, maxY)
                Behavior on x {
                    enabled: root.trayRoot.menuMapped

                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                TrayMenuStack {
                    id: menuSurface

                    open: root.trayRoot.menuShowing
                    x: root.trayRoot.shadowPadding
                    y: root.trayRoot.shadowPadding
                    onEntered: {
                        root.closeTimer.stop();
                        root.hideTimer.stop();
                    }
                    onEntryActivated: root.trayRoot.closeMenu()
                    onExited: root.trayRoot.scheduleClose()
                }
            }
        }
    }
}
