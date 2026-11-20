pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import AnotherRipple

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property int   actionButtonIconSize: size === "small" ? 16 : size === "large" ? 36 : 24
    readonly property int   actionButtonRadius: size === "small" ? 12 : size === "regular" ? 12 : size === "large" ? 28 : 16
    readonly property int   actionButtonSize: size === "small" ? 32 : size === "regular" ? 40 : size === "large" ? 96 : 56
    readonly property color backgroundColor: isInteractive || color.a === 0 ? color : Qt.alpha(color, 0.12)
    readonly property bool  isInteractive: enabled && buttonEnabled
    readonly property bool  keyboardFocused: activeFocus

    property alias          backgroundRadius: background.radius
    property bool           buttonEnabled: true
    property color          color: Colours.m3Colors.m3PrimaryContainer
    property string         disabledTooltipText: ""
    property bool           hovered: hoverHandler.hovered
    property IconComponent  icon: IconComponent {}
    property bool           pressed: tapHandler.pressed
    property string         size: "medium"
    property bool           spinning: false
    property int            tooltipPosition: Edges.Bottom
    property string         tooltipText: ""

    signal                  clicked

    implicitHeight: actionButtonSize
    implicitWidth: actionButtonSize

    // qmllint disable
    states: [
        State {
            name: "disabled"
            when: !root.isInteractive

            PropertyChanges {
                opacity: 0.38
                target: root
            }
        },
        State {
            name: "focused"
            when: root.isInteractive && root.keyboardFocused

            PropertyChanges {
                opacity: 1
                target: focusRing
            }
        },
        State {
            name: "normal"
            when: root.isInteractive && !root.hovered && !root.pressed && !root.keyboardFocused
        }
    ]
    Keys.onReturnPressed: event => {
        if (isInteractive) {
            clicked();
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        if (isInteractive) {
            clicked();
            event.accepted = true;
        }
    }
    onSpinningChanged: {
        if (!spinning) {
            const r           = ((iconItem.rotation % 360) + 360) % 360;
            // Snap to normalized angle first so the animation starts from the visible angle.
            iconItem.rotation = r;
            // Shortest path back to 0: go forward to 360 if past halfway, then snap to 0 in onFinished.
            resetAnim.to      = r > 180 ? 360 : 0;
            resetAnim.restart();
        } else {
            resetAnim.stop();
        }
    }

    NumberAnimation {
        id: resetAnim

        duration: Appearance.animations.durations.normal
        easing.type: Easing.OutCubic
        property: "rotation"
        target: iconItem
        onFinished: {
            if (iconItem.rotation >= 359.9)
                iconItem.rotation = 0;
        }
    }

    // qmllint enable

    Elevation {
        level: root.hovered && !root.pressed ? 4 : 3
        radius: background.radius
        visible: root.backgroundColor.a > 0 && root.isInteractive
    }

    ClippingRectangle {
        id: background

        anchors.fill: parent
        color: root.backgroundColor
        radius: root.isInteractive && root.pressed ? height * 0.5 : root.actionButtonRadius
        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.type: Easing.OutBack
            }
        }

        SimpleRipple {
            anchors.fill: parent
            color: Colours.m3Colors.m3OnSurfaceVariant
            visible: root.isInteractive
        }

        ParticleRipple {
            anchors.fill: parent
            color: Colours.m3Colors.m3OutlineVariant
            opacity: 0.5
            particleCount: 2
            visible: root.isInteractive
        }
    }

    StateLayer {
        anchors.fill: parent
        color: root.icon.color
        layerEnabled: root.isInteractive
        layerHovered: root.hovered
        layerPressed: root.pressed
        radius: background.radius
    }

    Rectangle {
        id: focusRing

        anchors.fill: parent
        border.color: Colours.m3Colors.m3Primary
        border.width: 2
        color: "transparent"
        opacity: 0
        radius: background.radius
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    Icon {
        id: iconItem

        anchors.centerIn: parent
        color: root.icon.color
        font.pixelSize: root.icon.size
        icon: root.icon.name
        RotationAnimator on rotation {
            duration: Appearance.animations.durations.extraLarge
            easing.type: Easing.Linear
            from: 0
            loops: Animation.Infinite
            running: root.spinning
            to: 360
        }
    }

    HoverHandler {
        id: hoverHandler

        cursorShape: root.isInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tapHandler

        enabled: root.isInteractive
        onTapped: root.clicked()
    }

    Tooltip {
        anchorItem: root
        enabled: root.isInteractive ? root.tooltipText.length > 0 : root.disabledTooltipText.length > 0
        position: root.tooltipPosition
        text: !root.isInteractive && root.disabledTooltipText.length > 0 ? root.disabledTooltipText : root.tooltipText
    }

    component IconComponent: QtObject {
        property color  color: Colours.m3Colors.m3OnPrimaryContainer
        property string name: ""
        property int    size: root.actionButtonIconSize
    }
}
