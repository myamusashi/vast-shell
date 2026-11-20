pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property bool     allowHover
    required property bool     captureEnabled
    required property int      cardIndex
    required property real     cardHeight
    required property real     cardWidth
    required property bool     isDragged
    required property bool     isHovered
    required property bool     isKeyboardFocused
    required property var      toplevel

    readonly property var      desktopEntry: DockServices.entryForToplevel(root.toplevel)
    readonly property string   iconPath: Quickshell.iconPath(desktopEntry?.icon ?? "", "application-x-executable")
    readonly property Toplevel waylandHandle: root.toplevel?.wayland ?? null // qmllint disable
    readonly property string   windowAddress: root.toplevel?.address ?? ""
    readonly property string   windowTitle: root.toplevel?.title ?? root.toplevel?.lastIpcObject?.title ?? ""

    property bool              dragging: false

    signal                     activated(var toplevel)
    signal                     closeRequested(var toplevel)
    signal                     dragEnded(real sceneX, real sceneY)
    signal                     dragMoved(real sceneX, real sceneY)
    signal                     dragStarted(var toplevel, real sceneX, real sceneY, real cardWidth, real cardHeight)
    signal                     hoverEntered(string windowAddress, int cardIndex)
    signal                     hoverExited(string windowAddress)

    implicitHeight: root.cardHeight
    implicitWidth: root.cardWidth
    opacity: root.isDragged ? 0.35 : 1.0
    scale: root.isKeyboardFocused ? 1.02 : (root.isHovered ? 1.01 : 1.0)
    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }
    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Elevation {
        level: root.isKeyboardFocused ? 3 : (root.isHovered ? 2 : 1)
        radius: cardSurface.radius
    }

    StyledRect {
        id: cardSurface

        anchors.fill: parent
        border.color: root.isKeyboardFocused ? Colours.m3Colors.m3Primary : (root.isHovered ? Colours.m3Colors.m3Outline : Colours.m3Colors.m3OutlineVariant)
        border.width: root.isKeyboardFocused ? 2 : 1
        clip: true
        color: Colours.m3Colors.m3SurfaceContainerHigh
        radius: Appearance.rounding.normal
        Behavior on border.color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            StyledRect {
                id: headerBar

                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: root.isKeyboardFocused ? Qt.alpha(Colours.m3Colors.m3Primary, 0.2) : Colours.m3Colors.m3SurfaceContainerHighest
                radius: 0

                RowLayout {

                    anchors {
                        fill: parent
                        leftMargin: Appearance.padding.normal
                        rightMargin: Appearance.padding.small
                    }

                    spacing: Appearance.spacing.small

                    IconImage {
                        Layout.alignment: Qt.AlignVCenter
                        backer.cache: true
                        implicitSize: 18
                        source: root.iconPath
                    }

                    StyledText {
                        id: titleText

                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.Medium
                        text: root.windowTitle

                        Tooltip {
                            anchorItem: titleText
                            enabled: titleText.truncated && !root.dragging && !root.isDragged
                            text: root.windowTitle
                        }
                    }

                    StyledRect {
                        id: closeButton

                        Layout.alignment: Qt.AlignVCenter
                        color: closeArea.containsMouse ? Qt.alpha(Colours.m3Colors.m3Error, 0.2) : "transparent"
                        implicitHeight: 24
                        implicitWidth: 24
                        radius: Appearance.rounding.full

                        Icon {
                            anchors.centerIn: parent
                            color: closeArea.containsMouse ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurfaceVariant
                            font.pixelSize: Appearance.fonts.size.large
                            icon: "close"
                        }

                        MArea {
                            id: closeArea

                            acceptedButtons: Qt.LeftButton
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            layerColor: Colours.m3Colors.m3Error
                            layerRadius: closeButton.radius
                            onClicked: root.closeRequested(root.toplevel)
                        }

                        Tooltip {
                            anchorItem: closeButton
                            enabled: !root.dragging && !root.isDragged
                            text: qsTr("Close window")
                        }
                    }
                }
            }

            Item {
                id: previewArea

                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: true

                ScreencopyView {
                    id: screencopyView

                    anchors.centerIn: parent
                    captureSource: root.captureEnabled ? root.waylandHandle : null
                    constraintSize: Qt.size(Math.max(1, previewArea.width - Appearance.padding.small * 2), Math.max(1, previewArea.height - Appearance.padding.small * 2))
                    height: implicitHeight
                    live: Configs.overview.live
                    paintCursor: false
                    visible: hasContent
                    width: implicitWidth
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small
                    visible: !screencopyView.hasContent
                    width: Math.max(0, previewArea.width - Appearance.padding.large * 2)

                    IconImage {
                        Layout.alignment: Qt.AlignHCenter
                        backer.cache: true
                        implicitSize: 48
                        source: root.iconPath
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        horizontalAlignment: Text.AlignHCenter
                        text: root.windowTitle
                    }
                }

                MArea {
                    id: cardMouseArea

                    readonly property int dragThreshold: 8

                    property bool         dragActive: false
                    property point        pressScenePoint: Qt.point(0, 0)
                    property bool         suppressNextClick: false

                    acceptedButtons: Qt.LeftButton
                    anchors.fill: parent
                    cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    hoverEnabled: false
                    layerRadius: 0
                    onCanceled: {
                        if (!dragActive)
                            return;
                        dragActive    = false;
                        root.dragging = false;
                        root.dragEnded(-1, -1);
                    }
                    onClicked: {
                        if (suppressNextClick) {
                            suppressNextClick = false;
                            return;
                        }
                        root.activated(root.toplevel);
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        const currentScenePoint = mapToItem(null, mouse.x, mouse.y);
                        if (!dragActive && OverviewServices.hasExceededDragThreshold(currentScenePoint, pressScenePoint, dragThreshold)) {
                            dragActive    = true;
                            root.dragging = true;
                            root.dragStarted(root.toplevel, currentScenePoint.x, currentScenePoint.y, root.cardWidth, root.cardHeight);
                        }
                        if (dragActive)
                            root.dragMoved(currentScenePoint.x, currentScenePoint.y);
                    }
                    onPressed: mouse => {
                        pressScenePoint   = mapToItem(null, mouse.x, mouse.y);
                        dragActive        = false;
                        suppressNextClick = false;
                    }
                    onReleased: mouse => {
                        if (!dragActive)
                            return;
                        const releaseScenePoint = mapToItem(null, mouse.x, mouse.y);
                        suppressNextClick       = true;
                        dragActive              = false;
                        root.dragging           = false;
                        root.dragEnded(releaseScenePoint.x, releaseScenePoint.y);
                    }
                }
            }
        }

        HoverHandler {
            blocking: false
            enabled: root.allowHover
            onHoveredChanged: {
                if (hovered)
                    root.hoverEntered(root.windowAddress, root.cardIndex);
                else
                    root.hoverExited(root.windowAddress);
            }
        }
    }
}
