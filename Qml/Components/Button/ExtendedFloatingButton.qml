pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import Vast.Utils

Item {
    id: root

    readonly property color backgroundColor: enabled || color.a === 0 ? color : Qt.alpha(color, 0.12)
    property alias backgroundRadius: background.radius
    property color color: Colours.m3Colors.m3Primary
    property bool hovered: hoverHandler.hovered
    property IconComponent icon: IconComponent {
    }
    property bool keyboardFocusable: true
    readonly property bool keyboardFocused: activeFocus
    property bool outlined: false
    property int paddingBottom: 10
    property int paddingLeft: icon.name !== "" ? 16 : 24
    property int paddingRight: 24
    property int paddingTop: 10
    property bool pressed: tapHandler.pressed
    property color rippleColor: Colours.m3Colors.m3OnPrimary
    property int spacing: 8
    property string text: ""
    property color textColor: Colours.m3Colors.m3OnPrimary
    property int textSize: Appearance.fonts.size.normal

    signal clicked

    implicitHeight: 40
    implicitWidth: contentRow.implicitWidth + paddingLeft + paddingRight

    // qmllint disable
    states: [
        State {
            name: "disabled"
            when: !root.enabled

            PropertyChanges {
                opacity: 0.38
                target: root
            }
        },
        State {
            name: "pressed"
            when: root.enabled && root.pressed

            PropertyChanges {
                scale: 0.98
                target: background
            }
        },
        State {
            name: "focused"
            when: root.enabled && root.keyboardFocused

            PropertyChanges {
                opacity: 1
                target: focusRing
            }
            PropertyChanges {
                opacity: 1
                target: focusHighlight
            }
        },
        State {
            name: "normal"
            when: root.enabled && !root.hovered && !root.pressed && !root.keyboardFocused
        }
    ]
    // qmllint enable

    transitions: [
        Transition {
            from: "*"
            to: "*"

            NAnim {
                duration: Appearance.animations.durations.small
                properties: "scale,opacity"
            }
        }
    ]

    Keys.onEnterPressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }
    Keys.onReturnPressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        if (enabled) {
            clicked();
            event.accepted = true;
        }
    }

    StyledRect {
        id: background

        anchors.fill: parent
        border.color: root.outlined ? Qt.alpha(Colours.m3Colors.m3OnSurface, root.enabled ? 1.0 : 0.38) : "transparent"
        border.width: root.outlined ? 1 : 0
        color: root.outlined ? "transparent" : root.backgroundColor
        radius: Appearance.rounding.normal
        transformOrigin: Item.Center

        SimpleRipple {
            anchors.fill: parent
            color: Colours.m3Colors.m3OnSurfaceVariant
            xClipRadius: background.radius
            yClipRadius: background.radius
        }
    }
    StateLayer {
        anchors.fill: parent
        color: root.textColor
        layerEnabled: root.enabled
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
    Rectangle {
        id: focusHighlight

        anchors.fill: parent
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.18)
        opacity: 0
        radius: background.radius

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }
    RowLayout {
        id: contentRow

        anchors.centerIn: parent
        spacing: root.spacing

        Icon {
            id: iconItem

            property real colorBlendProgress: 1.0
            property bool colorBlending: false
            property color colorFrom
            property color colorTo
            property color iconTarget: root.icon.color

            font.pixelSize: root.icon.size
            icon: root.icon.name
            visible: root.icon.name !== ""

            onColorBlendProgressChanged: {
                if (!colorBlending)
                    return;
                if (colorBlendProgress >= 1) {
                    color = colorTo;
                    colorBlending = false;
                } else if (colorBlendProgress > 0) {
                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                }
            }
            onIconTargetChanged: {
                iconColorBlendAnim.stop();
                colorFrom = iconItem.color;
                colorTo = iconTarget;
                colorBlending = true;
                colorBlendProgress = 0.0;
                iconColorBlendAnim.start();
            }

            NAnim {
                id: iconColorBlendAnim

                duration: Appearance.animations.durations.small
                from: 0.0
                property: "colorBlendProgress"
                target: iconItem
                to: 1.0
            }
        }
        Loader {
            id: styledTextLoader

            active: root.text !== ""
            asynchronous: false

            sourceComponent: StyledText {
                id: styledTextItem

                property real colorBlendProgress: 1.0
                property bool colorBlending: false
                property color colorFrom
                property color colorTo
                property color textTarget: root.textColor

                font.letterSpacing: 0.1
                font.pixelSize: root.textSize
                font.weight: Font.Medium
                text: root.text

                onColorBlendProgressChanged: {
                    if (!colorBlending)
                        return;
                    if (colorBlendProgress >= 1) {
                        color = colorTo;
                        colorBlending = false;
                    } else if (colorBlendProgress > 0) {
                        color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                    }
                }
                onTextTargetChanged: {
                    textColorBlendAnim.stop();
                    colorFrom = styledTextItem.color;
                    colorTo = textTarget;
                    colorBlending = true;
                    colorBlendProgress = 0.0;
                    textColorBlendAnim.start();
                }

                NAnim {
                    id: textColorBlendAnim

                    duration: Appearance.animations.durations.small
                    from: 0.0
                    property: "colorBlendProgress"
                    target: styledTextItem
                    to: 1.0
                }
            }
        }
    }
    HoverHandler {
        id: hoverHandler

        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
    TapHandler {
        id: tapHandler

        enabled: root.enabled

        onTapped: root.clicked()
    }

    component IconComponent: QtObject {
        property color color: Colours.m3Colors.m3OnSurface
        property string name: ""
        property int size: Appearance.fonts.size.large * 1.2
    }
}
