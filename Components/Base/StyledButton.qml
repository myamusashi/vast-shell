pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property color _bgColor: {
        if (!enabled)
            return Qt.alpha(color, 0.12);
        if (pressed)
            return Qt.darker(color, 1.18);
        if (hovered)
            return Qt.darker(color, 1.08);
        return color;
    }

    readonly property color _textColor: Qt.alpha(textColor, enabled ? 1.0 : 0.38)

    property alias bgRadius: background.radius
    property string text: ""
    property int textSize: Appearance.fonts.size.normal

    property bool enabled: true
    property bool pressed
    property bool hovered
    property bool outlined: false
    property color color: "#6750A4"
    property color textColor: "#FFFFFF"
    property color rippleColor: "#FFFFFF"
    property IconComponent icon: IconComponent {}

    property int leftPad: icon.name !== "" ? 16 : 24
    property int rightPad: 24
    property int topPad: 10
    property int bottomPad: 10
    property int spacing: 8

    signal clicked

    implicitWidth: contentRow.implicitWidth + leftPad + rightPad
    implicitHeight: 40

    states: [
        State {
            name: "disabled"
            when: !root.enabled
            PropertyChanges {
                target: root
                opacity: 0.38
            }
        },
        State {
            name: "pressed"
            when: root.enabled && root.pressed
            PropertyChanges {
                target: background
                scale: 0.98
            }
        },
        State {
            name: "hovered"
            when: root.enabled && root.hovered && !root.pressed
            PropertyChanges {
                target: background
                scale: 1.02
            }
        },
        State {
            name: "normal"
            when: root.enabled && !root.hovered && !root.pressed
        }
    ]

    transitions: [
        Transition {
            from: "*"
            to: "*"
            NAnim {
                properties: "scale,opacity"
                duration: Appearance.animations.durations.small
            }
        }
    ]

    StyledRect {
        id: background

        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.outlined ? "transparent" : root._bgColor
        border.width: root.outlined ? 1 : 0
        border.color: root.outlined ? Qt.alpha(root.color, root.enabled ? 1.0 : 0.38) : "transparent"
        transformOrigin: Item.Center

        SimpleRipple {
            anchors.fill: parent
            xClipRadius: background.radius
            yClipRadius: background.radius
            color: Colours.m3Colors.m3OnSurfaceVariant
        }
    }

    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: root.spacing

        Icon {
            visible: root.icon.name !== ""
            icon: root.icon.name
            font.pixelSize: root.icon.size
            color: root.icon.color

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        Loader {
            id: styledTextLoader

            active: root.text !== ""
            asynchronous: false
            sourceComponent: StyledText {
                text: root.text
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                font.letterSpacing: 0.1
                color: root._textColor

                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                    }
                }
            }
        }
    }

    HoverHandler {
        id: hoverHandler

        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    hovered: hoverHandler.hovered

    TapHandler {
        id: tapHandler

        enabled: root.enabled
        onTapped: root.clicked()
    }

    pressed: tapHandler.pressed

    component IconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSurface
        property string name: ""
        property int size: Appearance.fonts.size.large * 1.2
    }
}
