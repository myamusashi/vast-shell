pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root
    required property ShellScreen monitor

    readonly property real        barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight
    readonly property real        horizontalPadding: Appearance.spacing.normal
    readonly property real        shadowPadding: 12

    property var                  activeMenu: null
    property int                  hoveredIndex: -1
    property bool                 iconHovered: false
    property bool                 menuHovered: false
    property bool                 menuMapped: false
    property bool                 menuShowing: false
    property real                 menuX: 0

    function                      closeMenu(): void {
        closeT.stop();
        hideT.stop();
        if (!root.menuMapped)
            return;
        root.menuShowing = false;
        hideT.restart();
    }

    function                      finishClose(): void {
        closeT.stop();
        root.menuMapped = false;
        root.activeMenu = null;
    }

    function                      onMenuEntered(): void {
        root.menuHovered = true;
        closeT.stop();
        hideT.stop();
        if (root.menuMapped && !root.menuShowing && root.activeMenu !== null)
            root.menuShowing = true;
    }

    function                      onMenuExited(): void {
        root.menuHovered = false;
        root.scheduleClose();
    }

    function                      openMenuFor(item: var, iconItem: Item): void {
        closeT.stop();
        hideT.stop();
        if (!item || !item.hasMenu) {
            root.iconHovered = false;
            root.scheduleClose();
            return;
        }
        root.iconHovered = true;
        root.menuX       = iconItem.mapToGlobal(0, 0).x - root.monitor.x;
        root.activeMenu  = item.menu;
        root.menuMapped  = true;
        root.menuShowing = true;
    }

    function                      scheduleClose(): void {
        if (!root.menuShowing || root.iconHovered || root.menuHovered)
            return;
        closeT.restart();
    }

    color: "transparent"
    implicitHeight: 35
    implicitWidth: visible ? systemTrayRow.width + horizontalPadding * 1.2 : 0
    radius: Appearance.rounding.small
    visible: SystemTray.items.values.length > 0
    Behavior on implicitWidth {
        NAnim {}
    }

    Item {
        anchors.centerIn: parent
        height: 25
        width: systemTrayRow.width

        StyledRect {
            id: hoverHighlight

            color: Colours.m3Colors.m3Primary
            height: 25
            radius: Appearance.rounding.normal
            visible: root.hoveredIndex >= 0 && root.hoveredIndex < trayRepeater.count
            width: 25
            x: root.hoveredIndex >= 0 ? root.hoveredIndex * (25 + systemTrayRow.spacing) : 0
            y: 0
            Behavior on x {
                enabled: hoverHighlight.visible

                NAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        Row {
            id: systemTrayRow

            spacing: Appearance.spacing.small

            Repeater {
                id: trayRepeater

                model: ScriptModel {
                    objectProp: "id"
                    values: [...SystemTray.items.values]
                }
                delegate: Item {
                    id: delegateTray

                    required property int            index
                    required property SystemTrayItem modelData

                    readonly property bool           isHovered: root.hoveredIndex === index

                    height: 25
                    width: 25

                    IconImage {
                        anchors.centerIn: parent
                        asynchronous: true
                        backer.cache: true
                        height: Appearance.fonts.size.large * 1.2
                        layer.enabled: true
                        mipmap: true
                        smooth: true
                        source: IconUtils.iconSource(delegateTray.modelData ? delegateTray.modelData.icon : "")
                        width: Appearance.fonts.size.large * 1.2
                        layer.effect: MultiEffect {
                            autoPaddingEnabled: false
                            colorization: 1.0
                            colorizationColor: delegateTray.isHovered ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3Primary
                        }
                    }
                }
            }
        }

        MouseArea {
            id: trayMouseArea

            function updateHover(mouseX: real): void {
                const slot = 25 + systemTrayRow.spacing;
                const idx  = Math.floor(mouseX / slot);
                if (idx < 0 || idx >= trayRepeater.count) {
                    root.hoveredIndex = -1;
                    root.iconHovered  = false;
                    root.scheduleClose();
                    return;
                }
                if (root.hoveredIndex !== idx) {
                    root.hoveredIndex = idx;
                    const delegate    = trayRepeater.itemAt(idx);
                    const item        = SystemTray.items.values[idx];
                    if (delegate && item)
                        root.openMenuFor(item, delegate);
                }
            }

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: mouse => {
                const slot = 25 + systemTrayRow.spacing;
                const idx  = Math.floor(mouse.x / slot);
                if (idx < 0 || idx >= trayRepeater.count)
                    return;
                const item = SystemTray.items.values[idx];
                if (!item || mouse.button !== Qt.LeftButton)
                    return;
                if (item.hasMenu && item.onlyMenu)
                    return;
                item.activate();
            }
            onEntered: updateHover(mouseX)
            onExited: {
                root.hoveredIndex = -1;
                root.iconHovered  = false;
                root.scheduleClose();
            }
            onPositionChanged: mouse => updateHover(mouse.x)
        }
    }

    Timer {
        id: closeT

        interval: Appearance.animations.durations.normal
        onTriggered: {
            if (!root.iconHovered && !root.menuHovered)
                root.closeMenu();
        }
    }

    Timer {
        id: hideT

        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.finishClose()
    }

    TrayPanel {
        screen: root.monitor
        trayRoot: root
    }
}
