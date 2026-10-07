pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Effects
import qs.Components.Base
import qs.Components.Menu
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    readonly property real barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight
    readonly property real horizontalPadding: Appearance.spacing.normal
    readonly property real shadowPadding: 12

    property var           activeIconItem: null
    property var           activeMenu: null
    property bool          menuMapped: false
    property bool          menuShowing: false
    property real          menuX: 0
    property alias         widgetHeight: root.implicitHeight

    function               closeMenu(): void {
        closeTimer.stop();
        hideTimer.stop();
        if (!root.menuMapped)
            return;
        root.menuShowing = false;
        hideTimer.restart();
    }
    function               finishClose(): void {
        closeTimer.stop();
        root.menuMapped     = false;
        root.activeIconItem = null;
        root.activeMenu     = null;
    }
    function               openMenuFor(item, iconItem): void {
        closeTimer.stop();
        hideTimer.stop();
        if (!item || !item.hasMenu) {
            root.closeMenu();
            return;
        }
        root.menuX          = iconItem.mapToGlobal(0, 0).x;
        root.activeIconItem = iconItem;
        if (root.menuShowing && root.activeMenu === item.menu)
            return;
        root.activeMenu  = item.menu;
        root.menuShowing = true;
        root.menuMapped  = true;
    }
    function               scheduleClose(): void {
        if (!root.menuMapped)
            return;
        closeTimer.restart();
    }

    color: "transparent"
    implicitHeight: 35
    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    radius: Appearance.rounding.small
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

                property string                  iconSource: IconUtils.iconSource(modelData ? modelData.icon : "")

                height: 25
                width: 25

                StyledRect {
                    id: bgTrayIcon

                    property color target: trayItemArea.containsMouse ? Colours.m3Colors.m3Primary : "transparent"

                    height: 25
                    radius: Appearance.rounding.normal
                    width: 25

                    BlendColor {
                        host: bgTrayIcon
                        target: bgTrayIcon.target
                    }
                }

                IconImage {
                    anchors.centerIn: parent
                    asynchronous: true
                    backer.cache: true
                    height: Appearance.fonts.size.large * 1.2
                    layer.enabled: true
                    mipmap: true
                    smooth: true
                    source: delegateTray.iconSource
                    width: Appearance.fonts.size.large * 1.2
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

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: mouse => {
                        if (!delegateTray.modelData || mouse.button !== Qt.LeftButton)
                            return;
                        if (delegateTray.modelData.hasMenu && delegateTray.modelData.onlyMenu)
                            return;
                        delegateTray.modelData.activate();
                    }
                    onEntered: root.openMenuFor(delegateTray.modelData, delegateTray)
                    onExited: root.scheduleClose()
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

    LazyLoader {
        loading: true
        component: PanelWindow {
            HyprlandWindow.visibleMask: mask // qmllint disable
            WlrLayershell.layer: menuSurface.open ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.namespace: "shell:drawers"
            aboveWindows: false
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {
                item: menuSurface
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
                    if (root.activeMenu !== null)
                        Qt.callLater(() => menuSurface.openMenu(root.activeMenu)); // qmllint disable
                }

                target: root
            }

            Item {
                id: panelRoot

                anchors.fill: parent

                Item {
                    id: menuHost

                    readonly property real maxX: panelRoot.width - menuSurface.width - root.shadowPadding
                    readonly property real maxY: panelRoot.height - menuSurface.height - root.shadowPadding

                    height: menuSurface.height + root.shadowPadding * 2
                    width: menuSurface.width + root.shadowPadding * 2
                    x: Math.max(root.shadowPadding, Math.min(root.menuX - root.shadowPadding - menuSurface.bodyInsetX, maxX))
                    y: Math.min(root.barBottom - root.shadowPadding, maxY)
                    Behavior on x {
                        enabled: root.menuMapped

                        NAnim {
                            duration: Appearance.animations.durations.expressiveDefaultSpatial
                            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                        }
                    }

                    TrayMenuStack {
                        id: menuSurface

                        open: root.menuShowing
                        x: root.shadowPadding
                        y: root.shadowPadding
                        onEntered: {
                            closeTimer.stop();
                            hideTimer.stop();
                        }
                        onEntryActivated: root.closeMenu()
                        onExited: root.scheduleClose()
                    }
                }
            }
        }
    }
}
