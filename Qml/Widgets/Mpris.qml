pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    readonly property int index: 0

    color: "transparent"
    implicitHeight: parent.height
    implicitWidth: mediaInfo.width

    RowLayout {
        id: mediaInfo

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        RowButton {
            model: [
                {
                    icon: "skip_previous"
                },
                {
                    icon: Players.active === null ? "question_mark" : Players.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle"
                },
                {
                    icon: "skip_next"
                }
            ]
            contentColor: Colours.m3Colors.m3OnSecondaryContainer
            containerColor: Colours.m3Colors.m3SecondaryContainer
            onButtonClicked: index => {
                if (index === 0)
                    Players.active?.previous();
                else if (index === 1)
                    Players.active?.togglePlaying();
                else
                    Players.active?.next();
            }
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            font.weight: Font.DemiBold
            text: Players.active === null ? "null" : Players.active.trackArtist
        }
    }

    component RowButton: Row {
        id: root

        property int    buttonHeight: 24
        property int    buttonWidth: 40
        property color  containerColor
        property color  contentColor
        property real   disabledContainerOpacity: 0.10
        property real   disabledContentOpacity: 0.38
        property string iconFontFamily: "Material Symbols Rounded"
        property int    iconSize: 20
        property int    innerCornerRadius: 4
        property var    model: []

        signal          buttonClicked(int index)

        spacing: 2

        Repeater {
            model: root.model
            delegate: Rectangle {
                id: button

                required property int  index
                required property var  modelData

                readonly property real fullRadius: height / 2
                readonly property bool isEnabled: modelData.enabled !== false
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.model.length - 1

                property real          innerRadius: mouseArea.pressed && isEnabled ? fullRadius : root.innerCornerRadius

                implicitWidth: root.buttonWidth
                implicitHeight: root.buttonHeight
                color: isEnabled ? root.containerColor : Qt.alpha(root.contentColor, root.disabledContainerOpacity)
                topLeftRadius: isFirst ? fullRadius : innerRadius
                bottomLeftRadius: isFirst ? fullRadius : innerRadius
                topRightRadius: isLast ? fullRadius : innerRadius
                bottomRightRadius: isLast ? fullRadius : innerRadius
                Behavior on innerRadius {
                    NAnim {}
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: button.topLeftRadius
                    bottomLeftRadius: button.bottomLeftRadius
                    topRightRadius: button.topRightRadius
                    bottomRightRadius: button.bottomRightRadius
                    color: root.contentColor
                    opacity: !button.isEnabled ? 0 : mouseArea.pressed ? 0.10 : mouseArea.containsMouse ? 0.08 : 0
                    Behavior on opacity {
                        NAnim {}
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    icon: button.modelData.icon
                    font.pixelSize: root.iconSize
                    color: root.contentColor
                    opacity: button.isEnabled ? 1 : root.disabledContentOpacity
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    enabled: button.isEnabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.buttonClicked(button.index)
                }
            }
        }
    }
}
