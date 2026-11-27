pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property string activeFocusZone
    required property string inputMode
    required property bool   isTargetSameWorkspace
    required property var    lockedToplevel
    required property real   openProgress
    required property string targetWorkspaceLabel

    readonly property bool   hasLockedWindow: root.lockedToplevel !== null
    readonly property var    lockedEntry: DockServices.entryForToplevel(root.lockedToplevel)
    readonly property string lockedIconPath: Quickshell.iconPath(root.lockedEntry?.icon ?? "", "application-x-executable")
    readonly property string lockedTitle: root.lockedToplevel?.title ?? root.lockedToplevel?.lastIpcObject?.title ?? ""
    readonly property real   maxIndicatorWidth: Math.max(260, parent ? parent.width - Appearance.margin.large * 2 : 900)
    readonly property bool   shouldShow: root.hasLockedWindow || root.showKeyboardHint
    readonly property bool   showKeyboardHint: !root.hasLockedWindow && root.activeFocusZone === "grid" && root.inputMode === "keyboard"
    readonly property color  surfaceColor: {
        if (root.hasLockedWindow)
            return Qt.alpha(Colours.m3Colors.m3SurfaceContainerHighest, 0.96);
        return Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.9);
    }

    property real            indicatorOpacity: root.shouldShow ? 1.0 : 0.0

    signal                   unlockRequested

    implicitHeight: indicatorSurface.implicitHeight
    implicitWidth: Math.min(root.maxIndicatorWidth, indicatorSurface.implicitWidth)
    opacity: root.indicatorOpacity * root.openProgress
    visible: root.opacity > 0.001
    Behavior on indicatorOpacity {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }
    transform: Translate {
        y: (1.0 - root.indicatorOpacity) * 8
    }

    Elevation {
        level: root.hasLockedWindow ? 3 : 2
        radius: indicatorSurface.radius
    }

    StyledRect {
        id: indicatorSurface

        anchors.fill: parent
        border.color: root.hasLockedWindow ? Colours.m3Colors.m3Tertiary : Colours.m3Colors.m3OutlineVariant
        border.width: root.hasLockedWindow ? 2 : 1
        color: root.surfaceColor
        implicitHeight: Math.max(36, activeContentRow.implicitHeight + Appearance.padding.small * 2)
        implicitWidth: activeContentRow.implicitWidth + Appearance.padding.large * 2
        radius: Appearance.rounding.full
        Behavior on border.color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }

        RowLayout {
            id: activeContentRow

            anchors {
                bottom: parent.bottom
                left: parent.left
                leftMargin: Appearance.padding.large
                right: parent.right
                rightMargin: Appearance.padding.large
                top: parent.top
            }

            spacing: Appearance.spacing.normal

            StyledRect {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3TertiaryContainer
                implicitHeight: 24
                implicitWidth: lockedBadgeRow.implicitWidth + Appearance.padding.normal * 2
                radius: Appearance.rounding.full
                visible: root.hasLockedWindow

                RowLayout {
                    id: lockedBadgeRow

                    anchors.centerIn: parent
                    spacing: 4

                    Icon {
                        Layout.alignment: Qt.AlignVCenter
                        color: Colours.m3Colors.m3OnTertiaryContainer
                        font.pixelSize: Appearance.fonts.size.normal
                        icon: "lock"
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignVCenter
                        color: Colours.m3Colors.m3OnTertiaryContainer
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        text: qsTr("Locked")
                    }
                }
            }

            IconImage {
                Layout.alignment: Qt.AlignVCenter
                backer.cache: true
                implicitSize: 18
                source: root.lockedIconPath
                visible: root.hasLockedWindow
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 200
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.Medium
                text: root.lockedTitle
                visible: root.hasLockedWindow
            }

            Icon {
                Layout.alignment: Qt.AlignVCenter
                color: root.isTargetSameWorkspace ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.normal
                icon: "arrow_forward"
                visible: root.hasLockedWindow
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: root.isTargetSameWorkspace ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.small
                font.weight: Font.DemiBold
                text: root.isTargetSameWorkspace ? qsTr("Select workspace") : root.targetWorkspaceLabel
                visible: root.hasLockedWindow
            }

            StyledRect {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3OutlineVariant
                implicitHeight: 4
                implicitWidth: 4
                radius: 2
                visible: root.hasLockedWindow
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("←/→ Pick · Enter Move · 1-9 Jump · Esc Unlock")
                visible: root.hasLockedWindow
            }

            StyledRect {
                id: unlockButton

                Layout.alignment: Qt.AlignVCenter
                color: unlockArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Tertiary, 0.2) : "transparent"
                implicitHeight: 22
                implicitWidth: 22
                radius: Appearance.rounding.full
                visible: root.hasLockedWindow

                Icon {
                    anchors.centerIn: parent
                    color: unlockArea.containsMouse ? Colours.m3Colors.m3Tertiary : Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    icon: "close"
                }

                MArea {
                    id: unlockArea

                    acceptedButtons: Qt.LeftButton
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    layerColor: Colours.m3Colors.m3Tertiary
                    layerRadius: unlockButton.radius
                    onClicked: root.unlockRequested()
                }

                Tooltip {
                    anchorItem: unlockButton
                    enabled: root.hasLockedWindow
                    text: qsTr("Unlock window (Esc)")
                }
            }

            Icon {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.normal
                icon: "lock_open_right"
                visible: !root.hasLockedWindow
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Space / M Lock to move · Shift+←/→ Quick move · Enter Focus")
                visible: !root.hasLockedWindow
            }
        }
    }
}
