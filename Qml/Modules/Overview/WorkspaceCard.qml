pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool   allowHover
    required property bool   isDragOver
    required property bool   isHovered
    required property bool   isKeyboardFocused
    required property bool   isLockedSource
    required property bool   isMonitorActive
    required property bool   isNewWorkspaceCard
    required property bool   isSelected
    required property real   monitorHeight
    required property real   monitorWidth
    required property real   monitorX
    required property real   monitorY
    required property string wallpaperSource
    required property string workspaceAddress
    required property string workspaceName
    required property var    workspaceToplevels

    readonly property color  cardBorderColor: OverviewServices.workspaceCardBorderColor(root.isDragOver, root.isKeyboardFocused, root.isSelected, root.isHovered)
    readonly property int    cardBorderWidth: (root.isKeyboardFocused || root.isDragOver) ? 2 : 1
    readonly property int    elevationLevel: (root.isKeyboardFocused || root.isDragOver) ? 3 : ((root.isSelected || root.isHovered) ? 2 : 1)
    readonly property color  headerTextColor: {
        if (root.isDragOver)
            return Colours.m3Colors.m3Tertiary;
        if (root.isMonitorActive || root.isKeyboardFocused)
            return Colours.m3Colors.m3Primary;
        return Colours.m3Colors.m3OnSurface;
    }
    readonly property string resolvedLabel: OverviewServices.workspaceLabel(root.workspaceAddress, root.workspaceName, root.isNewWorkspaceCard)

    signal                   clicked(string workspaceAddress)
    signal                   doubleClicked(string workspaceAddress)
    signal                   hoverEntered(string workspaceAddress)
    signal                   hoverExited(string workspaceAddress)

    implicitHeight: 156
    implicitWidth: 220
    scale: (root.isKeyboardFocused || root.isDragOver) ? 1.04 : (root.isHovered ? 1.02 : 1.0)
    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Elevation {
        level: root.elevationLevel
        radius: cardContainer.radius
    }

    StyledRect {

        anchors {
            fill: cardContainer
            margins: -3
        }

        color: "transparent"
        border.color: root.isDragOver ? Qt.alpha(Colours.m3Colors.m3Tertiary, 0.35) : Qt.alpha(Colours.m3Colors.m3Primary, 0.28)
        border.width: 3
        radius: cardContainer.radius + 3
        visible: root.isKeyboardFocused || root.isDragOver
    }

    StyledRect {
        id: cardContainer

        anchors.fill: parent
        border.color: root.cardBorderColor
        border.width: root.cardBorderWidth
        clip: true
        color: (root.isSelected || root.isKeyboardFocused) ? Colours.m3Colors.m3SurfaceContainerHighest : Colours.m3Colors.m3SurfaceContainerHigh
        radius: Appearance.rounding.small
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

        ColumnLayout {

            anchors {
                fill: parent
                margins: Appearance.padding.larger
            }

            spacing: Appearance.spacing.smaller

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.fillWidth: true
                    color: root.headerTextColor
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: (root.isDragOver || root.isMonitorActive || root.isKeyboardFocused) ? Font.DemiBold : Font.Medium
                    text: root.resolvedLabel
                }

                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    color: Colours.m3Colors.m3Tertiary
                    font.pixelSize: Appearance.fonts.size.normal
                    icon: "arrow_downward"
                    visible: root.isDragOver
                }

                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    color: Colours.m3Colors.m3Tertiary
                    font.pixelSize: Appearance.fonts.size.normal
                    icon: "lock"
                    visible: !root.isDragOver && root.isLockedSource
                }

                StyledRect {
                    color: Colours.m3Colors.m3Primary
                    implicitHeight: 6
                    implicitWidth: 6
                    radius: 3
                    visible: !root.isNewWorkspaceCard && root.isMonitorActive
                }
            }

            ClippingRectangle {
                id: thumbnailBox

                Layout.fillHeight: true
                Layout.fillWidth: true
                color: Colours.m3Colors.m3SurfaceContainerLow
                radius: Math.max(4, Appearance.rounding.small - 4)

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                    source: (!root.isNewWorkspaceCard && root.wallpaperSource !== "") ? "file://" + root.wallpaperSource : ""
                    sourceSize: Qt.size(192, 108)
                    visible: !root.isNewWorkspaceCard && root.wallpaperSource !== ""
                }

                StyledRect {
                    anchors.fill: parent
                    color: Qt.alpha(Colours.m3Colors.m3Surface, 0.35)
                    visible: !root.isNewWorkspaceCard && root.wallpaperSource !== ""
                }

                Item {
                    id: miniTileContainer

                    anchors {
                        fill: parent
                        margins: Appearance.padding.small
                    }

                    visible: !root.isNewWorkspaceCard

                    Repeater {
                        model: ScriptModel {
                            objectProp: "address"
                            values: (root.workspaceToplevels ?? []).slice(0, 6)
                        }
                        delegate: StyledRect {
                            id: miniTile

                            required property int index
                            required property var modelData

                            readonly property var entry: DockServices.entryForToplevel(modelData)
                            readonly property var ipc: modelData?.lastIpcObject ?? null
                            readonly property var tileMetrics: OverviewServices.miniTileMetrics(ipc, index, root.monitorX, root.monitorY, root.monitorWidth, root.monitorHeight)

                            border.color: Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.9)
                            border.width: 1
                            color: Qt.alpha(Colours.m3Colors.m3SurfaceContainerHigh, 0.9)
                            height: Math.max(18, Math.round(miniTileContainer.height * tileMetrics.height))
                            radius: 4
                            width: Math.max(22, Math.round(miniTileContainer.width * tileMetrics.width))
                            x: Math.round(Math.max(0, Math.min(miniTileContainer.width - width, miniTileContainer.width * tileMetrics.x)))
                            y: Math.round(Math.max(0, Math.min(miniTileContainer.height - height, miniTileContainer.height * tileMetrics.y)))

                            IconImage {
                                anchors.centerIn: parent
                                backer.cache: true
                                implicitSize: Math.max(10, Math.min(18, Math.round(Math.min(miniTile.width, miniTile.height) * 0.6)))
                                source: Quickshell.iconPath(miniTile.entry?.icon ?? "", "application-x-executable")
                            }
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    color: root.isKeyboardFocused || root.isDragOver ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.extraLarge
                    icon: "add"
                    visible: root.isNewWorkspaceCard
                }
            }

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: 4
                implicitWidth: 32

                StyledRect {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3Primary
                    height: 4
                    radius: 2
                    width: (!root.isNewWorkspaceCard && root.isMonitorActive) ? 28 : 0
                    Behavior on width {
                        NAnim {
                            duration: Appearance.animations.durations.small
                        }
                    }
                }
            }
        }

        MArea {
            id: cardMouseArea

            acceptedButtons: Qt.LeftButton
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: root.allowHover
            layerColor: Colours.m3Colors.m3Primary
            layerRadius: cardContainer.radius
            onClicked: root.clicked(root.workspaceAddress)
            onDoubleClicked: {
                if (!root.isNewWorkspaceCard)
                    root.doubleClicked(root.workspaceAddress);
            }
        }

        HoverHandler {
            id: cardHoverHandler

            blocking: false
            enabled: root.allowHover
            onHoveredChanged: {
                if (hovered)
                    root.hoverEntered(root.workspaceAddress);
                else
                    root.hoverExited(root.workspaceAddress);
            }
        }
    }
}
