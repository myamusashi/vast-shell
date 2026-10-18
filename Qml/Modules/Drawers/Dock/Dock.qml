pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    required property ScreenBorder border

    readonly property bool         isDrawerOpenAbove: GlobalStates.isLauncherOpen || GlobalStates.isWallpaperSwitcherOpen

    property var                   parentWindow: null

    function                       syncReservedSpace(): void {
        if (!root.border.isFocusedMonitor)
            return;

        DockServices.setReservedBottomSpace(open ? depth : 0);
    }

    open: border.isDockVisible
    depth: Configs.dock.dockHeight
    edge: Qt.BottomEdge
    edgeOffset: 0
    length: GlobalStates.isSwitchingDrawer ? parent.width * GlobalStates.drawerLengthRatio : GlobalStates.isLauncherOpen ? parent.width * GlobalStates.launcherLengthRatio : GlobalStates.isWallpaperSwitcherOpen ? parent.width * GlobalStates.wallpaperSwitcherLengthRatio : DockServices.contentLength(parent.width)
    Behavior on length {
        enabled: !GlobalStates.isSwitchingDrawer

        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    filletRadius: Appearance.rounding.normal
    cornerRadius: root.isDrawerOpenAbove ? 0 : Appearance.rounding.large
    color: GlobalStates.drawerColors
    clipContent: true
    animateDepth: true
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    onOpenChanged: syncReservedSpace()
    onDepthChanged: syncReservedSpace()
    Component.onCompleted: syncReservedSpace()

    Connections {
        function onIsFocusedMonitorChanged() {
            root.syncReservedSpace();
        }

        target: root.border
    }

    Behavior on cornerRadius {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        anchors.fill: parent
        active: root.open
        asynchronous: true
        sourceComponent: Item {

            anchors {
                fill: parent
                margins: Appearance.margin.small
            }

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Row {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: implicitWidth
                    clip: true
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: DockServices.pinnedEntries
                        delegate: DockIcon {
                            required property var modelData

                            entryId: modelData.id
                            entry: modelData
                            toplevel: null
                            isPinned: true
                            iconSlot: Configs.dock.iconSlot
                            screen: root.border.window
                            onActivated: DockServices.activatePinned(modelData)
                            onHoverEntered: {
                                const point = mapToItem(null, 0, 0);
                                dockPreview.showForIcon(entryId, point.x, point.y, width, height);
                            }
                            onHoverExited: dockPreview.iconExited(entryId)
                        }
                    }
                }

                Rectangle {
                    implicitHeight: parent.height
                    implicitWidth: 1
                    color: Colours.m3Colors.m3OutlineVariant
                    Layout.minimumWidth: 1
                    Layout.preferredWidth: 1
                }

                Row {
                    Layout.fillWidth: false
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: implicitWidth
                    clip: true
                    spacing: Appearance.spacing.small

                    Repeater {
                        model: DockServices.activeToplevels
                        delegate: DockIcon {
                            required property var modelData

                            entryId: DockServices.entryForToplevel(modelData)?.id ?? ""
                            entry: DockServices.entryForToplevel(modelData)
                            toplevel: modelData
                            iconSlot: Configs.dock.iconSlot
                            screen: root.border.window
                            onActivated: DockServices.focusToplevel(modelData)
                            onHoverEntered: {
                                const point = mapToItem(null, 0, 0);
                                dockPreview.showForIcon(entryId, point.x, point.y, width, height);
                            }
                            onHoverExited: dockPreview.iconExited(entryId)
                        }
                    }
                }

                Rectangle {
                    implicitHeight: parent.height
                    implicitWidth: 1
                    color: Colours.m3Colors.m3OutlineVariant
                    Layout.minimumWidth: 1
                    Layout.preferredWidth: 1
                }

                Item {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: false
                    Layout.minimumWidth: implicitWidth
                    Layout.preferredWidth: implicitWidth
                    implicitHeight: Configs.dock.iconSlot + Appearance.spacing.small * 2
                    implicitWidth: Configs.dock.iconSlot + Appearance.spacing.small * 2

                    Icon {
                        anchors.centerIn: parent
                        color: GlobalStates.isLauncherOpen ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        icon: "apps"

                        MArea {
                            cursorShape: Qt.PointingHandCursor
                            onClicked: GlobalStates.togglePanel("launcher")
                        }
                    }
                }
            }

            DockPreview {
                id: dockPreview

                parentWindow: root.parentWindow
            }
        }
    }
}
