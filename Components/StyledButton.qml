pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

Button {
    id: root

    readonly property real _stateOpacity: {
        if (!enabled)
            return 0.38;
        if (pressed)
            return 0.88;
        if (hovered)
            return 0.92;
        return 1.0;
    }
    readonly property color _overlayColor: {
        if (pressed)
            return Qt.darker(root.color, 1.18);
        if (hovered)
            return Qt.darker(root.color, 1.08);
        return root.color;
    }
    readonly property color _effectiveTextColor: !enabled ? Colours.withAlpha(textColor, 0.38) : textColor

    property bool outlined: false
    property color color: "#6750A4"
    property color textColor: "#FFFFFF"
    property int textSize: 13
    property int iconSize: 18
    property real bgRadius: 8
    property string iconName: ""

    leftPadding: iconName !== "" ? 16 : 24
    rightPadding: 24
    topPadding: 10
    bottomPadding: 10
    spacing: 8

    contentItem: Row {
        spacing: root.spacing

        Icon {
            visible: root.iconName !== ""
            icon: root.iconName
            font.pixelSize: root.iconSize
            color: root._effectiveTextColor
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            visible: root.text !== ""
            text: root.text
            font.pixelSize: root.textSize
            font.weight: Font.Medium
            font.letterSpacing: 0.1
            color: root._effectiveTextColor
            verticalAlignment: Text.AlignVCenter
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    background: StyledRect {
        implicitWidth: 64
        implicitHeight: 40
        radius: root.bgRadius
        color: root.outlined ? "transparent" : root._overlayColor
        opacity: root._stateOpacity
        border {
            width: root.outlined ? 1 : 0
            color: root.outlined ? Qt.alpha(root.color, root.enabled ? 1.0 : 0.38) : "transparent"
        }

        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small * 1.2
            }
        }

        SimpleRipple {
            anchors.fill: parent
            acceptEvent: false
            color: Qt.alpha("white", 0.28)
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
