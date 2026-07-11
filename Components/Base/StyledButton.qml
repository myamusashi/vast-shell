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
            id: iconItem
            property color _c0From
            property color _c0To
            property bool _c0Active: false
            property real _c0Blend: 1.0

            on_C0BlendChanged: {
                if (!_c0Active) return
                if (_c0Blend >= 1) {
                    color = _c0To
                    _c0Active = false
                } else if (_c0Blend > 0) {
                    color = Colours.blendColors(_c0From, _c0To, _c0Blend)
                }
            }

            NumberAnimation {
                id: _c0Anim
                target: iconItem
                property: "_c0Blend"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.small
            }

            visible: root.icon.name !== ""
            icon: root.icon.name
            font.pixelSize: root.icon.size
            property color _iconTarget: root.icon.color

            on_IconTargetChanged: {
                _c0Anim.stop()
                _c0From = iconItem.color
                _c0To = _iconTarget
                _c0Active = true
                _c0Blend = 0.0
                _c0Anim.start()
            }
        }

        Loader {
            id: styledTextLoader

            active: root.text !== ""
            asynchronous: false
            sourceComponent: StyledText {
                id: styledTextItem
                property color _c1From
                property color _c1To
                property bool _c1Active: false
                property real _c1Blend: 1.0

                on_C1BlendChanged: {
                    if (!_c1Active) return
                    if (_c1Blend >= 1) {
                        color = _c1To
                        _c1Active = false
                    } else if (_c1Blend > 0) {
                        color = Colours.blendColors(_c1From, _c1To, _c1Blend)
                    }
                }

                NumberAnimation {
                    id: _c1Anim
                    target: styledTextItem
                    property: "_c1Blend"
                    from: 0.0
                    to: 1.0
                    duration: Appearance.animations.durations.small
                }

                text: root.text
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                font.letterSpacing: 0.1
                property color _textTarget: root._textColor

                on_TextTargetChanged: {
                    _c1Anim.stop()
                    _c1From = styledTextItem.color
                    _c1To = _textTarget
                    _c1Active = true
                    _c1Blend = 0.0
                    _c1Anim.start()
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
