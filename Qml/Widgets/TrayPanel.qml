pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils

LazyLoader {
    id: root

    required property var         trayRoot
    required property ShellScreen screen

    activeAsync: root.trayRoot.menuMapped
    component: PanelWindow {
        id: panelWindow

        BackgroundEffect.blurRegion: Region {
            item: menuSurface
        }
        HyprlandWindow.visibleMask: Region {
            item: menuSurface
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: LayerNamespaces.drawers
        aboveWindows: false
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        screen: root.screen
        Component.onCompleted: menuHost.armXAnimation()
        onWidthChanged: menuHost.armXAnimation()
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

        Item {
            id: menuHost

            readonly property real maxX: screenWidth - menuSurface.width - root.trayRoot.shadowPadding
            readonly property real maxY: screenHeight - menuSurface.height - root.trayRoot.shadowPadding
            readonly property real screenHeight: root.screen ? root.screen.height : panelWindow.height
            readonly property real screenWidth: root.screen ? root.screen.width - (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) : panelWindow.width

            property bool          animateX: false

            function               armXAnimation(): void {
                if (animateX || menuSurface.width <= 0 || panelWindow.width < screenWidth - 1)
                    return;
                Qt.callLater(() => {
                    if (panelWindow.width >= menuHost.screenWidth - 1 && root.trayRoot.menuMapped)
                        menuHost.animateX = true;
                });
            }

            height: menuSurface.height + root.trayRoot.shadowPadding * 2
            visible: panelWindow.width >= screenWidth - 1 && panelWindow.height > 0
            width: menuSurface.width + root.trayRoot.shadowPadding * 2
            x: Math.max(root.trayRoot.shadowPadding, Math.min(root.trayRoot.menuX - root.trayRoot.shadowPadding - menuSurface.bodyInsetX, maxX))
            y: Math.min(root.trayRoot.barBottom - root.trayRoot.shadowPadding, maxY)
            Behavior on x {
                enabled: menuHost.animateX && root.trayRoot.menuMapped

                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            TrayMenuStack {
                id: menuSurface

                activeMenu: root.trayRoot.activeMenu
                menuMapped: root.trayRoot.menuMapped
                open: root.trayRoot.menuShowing
                x: root.trayRoot.shadowPadding
                y: root.trayRoot.shadowPadding
                onEntered: root.trayRoot.onMenuEntered()
                onEntryActivated: root.trayRoot.closeMenu()
                onExited: root.trayRoot.onMenuExited()
            }
        }
    }
}
