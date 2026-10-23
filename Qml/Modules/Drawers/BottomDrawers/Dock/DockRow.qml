pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property ShellScreen screen

    property var                  parentWindow: null

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
                    screen: root.screen
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
                    screen: root.screen
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
