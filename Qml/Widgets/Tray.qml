pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

import qs.Components.Effects
import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    property alias widgetHeight: root.implicitHeight
    readonly property real horizontalPadding: Appearance.spacing.normal
    readonly property real shadowPadding: 12
    readonly property real barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight

    property var activeIconItem: null
    property var activeMenu: null
    property real menuX: 0
    property bool menuShowing: false
    property bool menuMapped: false

    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    implicitHeight: 35
    radius: Appearance.rounding.small
    color: "transparent"
    visible: SystemTray.items.values.length > 0

    Behavior on implicitWidth {
        NAnim {}
    }

    Row {
        id: systemTrayRow

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Repeater {
            model: SystemTray.items.values
            delegate: Item {
                id: delegateTray

                required property SystemTrayItem modelData
                property string iconSource: IconUtils.iconSource(modelData ? modelData.icon : "")

                width: 25
                height: 25

                StyledRect {
                    id: bgTrayIcon
                    property color target: trayItemArea.containsMouse ? Colours.m3Colors.m3Primary : "transparent"

                    BlendColor {
                        host: bgTrayIcon
                        target: bgTrayIcon.target
                    }

                    width: 25
                    height: 25
                    radius: Appearance.rounding.normal
                }

                IconImage {
                    anchors.centerIn: parent
                    width: Appearance.fonts.size.large * 1.2
                    height: Appearance.fonts.size.large * 1.2
                    source: delegateTray.iconSource
                    asynchronous: true
                    backer.cache: true
                    smooth: true
                    mipmap: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: false
                        colorization: 1.0
                        colorizationColor: {
                            if (trayItemArea.containsMouse)
                                return Colours.m3Colors.m3OnPrimary;

                            return Colours.m3Colors.m3Primary;
                        }
                    }
                }

                MArea {
                    id: trayItemArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.openMenuFor(delegateTray.modelData, delegateTray)
                    onExited: root.scheduleClose()
                    onClicked: mouse => {
                        if (!delegateTray.modelData || mouse.button !== Qt.LeftButton)
                            return;
                        if (delegateTray.modelData.hasMenu && delegateTray.modelData.onlyMenu)
                            return;
                        delegateTray.modelData.activate();
                    }
                }
            }
        }
    }

    Timer {
        id: closeTimer
        interval: Appearance.animations.durations.normal
        onTriggered: root.closeMenu()
    }

    Timer {
        id: hideTimer
        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.finishClose()
    }

    function openMenuFor(item, iconItem): void {
        closeTimer.stop();
        hideTimer.stop();
        if (!item || !item.hasMenu) {
            root.closeMenu();
            return;
        }
        root.menuX = iconItem.mapToGlobal(0, 0).x;
        root.activeIconItem = iconItem;
        if (root.menuShowing && root.activeMenu === item.menu)
            return;
        root.activeMenu = item.menu;
        root.menuShowing = true;
        root.menuMapped = true;
    }

    function scheduleClose(): void {
        if (!root.menuMapped)
            return;
        closeTimer.restart();
    }

    function closeMenu(): void {
        closeTimer.stop();
        hideTimer.stop();
        if (!root.menuMapped)
            return;
        root.menuShowing = false;
        hideTimer.restart();
    }

    function finishClose(): void {
        closeTimer.stop();
        root.menuMapped = false;
        root.activeIconItem = null;
        root.activeMenu = null;
    }

    LazyLoader {
        loading: true
        component: PanelWindow {
            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: false
            margins { // qmllint disable
                right: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
            WlrLayershell.namespace: "shell:drawers"
            WlrLayershell.layer: menuSurface.open ? WlrLayer.Top : WlrLayer.Bottom
            HyprlandWindow.visibleMask: mask // qmllint disable

            mask: Region {
                item: menuSurface
            }

            Connections {
                target: root

                function onActiveMenuChanged(): void {
                    if (root.activeMenu !== null)
                        menuSurface.openMenu(root.activeMenu);
                }
            }

            Item {
                id: panelRoot

                anchors.fill: parent

                Item {
                    id: menuHost

                    readonly property real maxX: panelRoot.width - menuSurface.width - root.shadowPadding
                    readonly property real maxY: panelRoot.height - menuSurface.height - root.shadowPadding

                    x: Math.max(root.shadowPadding, Math.min(root.menuX - root.shadowPadding - menuSurface.bodyInsetX, maxX))
                    y: Math.min(root.barBottom - root.shadowPadding, maxY)
                    width: menuSurface.width + root.shadowPadding * 2
                    height: menuSurface.height + root.shadowPadding * 2

                    Behavior on x {
                        enabled: root.menuMapped

                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    TrayMenuStack {
                        id: menuSurface

                        x: root.shadowPadding
                        y: root.shadowPadding
                        open: root.menuShowing

                        onEntered: {
                            closeTimer.stop();
                            hideTimer.stop();
                        }
                        onExited: root.scheduleClose()
                        onEntryActivated: root.closeMenu()
                    }
                }
            }
        }
    }
}
