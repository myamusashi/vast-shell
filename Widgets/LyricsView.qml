pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast

import qs.Core.Configs
import qs.Services
import qs.Components.Base

Item {
    id: root

    property alias listView: listView
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3Secondary
    property real activeFontSize: 22
    property real inactiveFontSize: 20

    ListView {
        id: listView

        anchors.fill: parent
        model: LyricsProvider.lines
        spacing: 16
        clip: true
        cacheBuffer: 0
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                positionViewAtBeginning();
            else
                positionViewAtIndex(currentIndex, ListView.Center);
        }

        Binding {
            target: listView
            property: "currentIndex"
            value: LyricsProvider.currentLineIndex
        }

        Connections {
            target: Lyrics

            function onLinesChanged() {
                listView.positionViewAtBeginning();
            }
        }

        delegate: Column {
            id: lineDelegate

            required property var modelData
            required property int index
            readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

            width: listView.width
            spacing: 4

            scale: isActiveLine ? 1.0 : 0.9
            opacity: {
                if (!Lyrics.synced)
                    return 1.0;
                return isActiveLine ? 1.0 : 0.45;
            }

            Behavior on scale {
                NAnim {
                    duration: Math.max(200, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on opacity {
                NAnim {
                    duration: Math.max(150, LyricsProvider.currentWordDuration)
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }

            Flow {
                width: parent.width
                spacing: 0

                Repeater {
                    model: lineDelegate.modelData.text

                    delegate: StyledText {
                        required property var modelData
                        text: modelData
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        font.family: "Noto Sans"
                        color: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor

                        Behavior on color {
                            CAnim {
                                duration: Math.max(150, LyricsProvider.currentWordDuration)
                                easing.bezierCurve: Appearance.animations.curves.emphasized
                            }
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: `(${lineDelegate.modelData.translation})`
                visible: lineDelegate.modelData.translation !== ""
                font.pixelSize: Appearance.fonts.size.normal
                font.family: "Noto Sans"
                color: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                opacity: 0.7

                Behavior on color {
                    CAnim {
                        duration: Math.max(150, LyricsProvider.currentWordDuration)
                        easing.bezierCurve: Appearance.animations.curves.emphasized
                    }
                }
            }
        }
    }
}
