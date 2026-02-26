pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    property alias textSize: styledText.font.pixelSize
    property alias bgRadius: background.radius
    property alias text: styledText.text

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
    property bool enabled: true
    property bool pressed: false
    property bool hovered: false
    property bool outlined: false
    property color color: "#6750A4"
    property color textColor: "#FFFFFF"
    property color rippleColor: "#FFFFFF"
    property IconComponent icon: IconComponent {}

    signal clicked

    implicitWidth: contentRow.implicitWidth + leftPad + rightPad
    implicitHeight: 40

    property int leftPad: icon.name !== "" ? 16 : 24
    property int rightPad: 24
    property int topPad: 10
    property int bottomPad: 10
    property int spacing: 8

    StyledRect {
        id: background

        anchors.fill: parent
        radius: 8
        color: root.outlined ? "transparent" : root._bgColor
        border.width: root.outlined ? 1 : 0
        border.color: root.outlined ? Qt.alpha(root.color, root.enabled ? 1.0 : 0.38) : "transparent"

        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }

        SimpleRipple {
            anchors.fill: parent
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

        StyledText {
            id: styledText
            visible: text !== ""
            font.pixelSize: 13
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

    HoverHandler {
        id: hoverHandler

        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onHoveredChanged: root.hovered = hoverHandler.hovered
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
        onPressedChanged: root.pressed = pressed
    }

    component IconComponent: QtObject {
        property string name: ""
        property color color: Colours.m3Colors.m3OnSurface
        property int size: Appearance.fonts.size.large * 1.2
    }
}
