pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Vast.Lyrics

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    property color activeColor: Colours.m3Colors.m3Primary
    property real  activeFontSize: 22
    property color inactiveColor: Colours.m3Colors.m3Secondary
    property real  inactiveFontSize: 20
    property alias listView: listView

    ListView {
        id: listView

        anchors.fill: parent
        cacheBuffer: 200
        clip: true
        currentIndex: LyricsProvider.currentLineIndex
        model: LyricsProvider.lines
        spacing: 16
        delegate: Column {
            id: lineDelegate

            required property int  index
            required property var  modelData

            readonly property bool isActiveLine: index === LyricsProvider.currentLineIndex

            opacity: {
                if (!Lyrics.synced)
                    return 1.0;
                return isActiveLine ? 1.0 : 0.45;
            }
            scale: isActiveLine ? 1.0 : 0.9
            spacing: 4
            width: listView.width
            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }
            Behavior on scale {
                NAnim {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
            }

            StyledText {
                id: lyricText

                color: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                renderType: Text.QtRendering
                style: Text.Raised
                styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
                text: lineDelegate.modelData.text
                width: parent.width
                wrapMode: Text.Wrap
                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                font {
                    family: "Noto Sans"
                    hintingPreference: Font.PreferNoHinting
                    kerning: true
                    pixelSize: Appearance.fonts.size.large
                    preferShaping: true
                    weight: Font.DemiBold
                }
            }

            StyledText {
                id: translationText

                color: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                opacity: 0.7
                style: Text.Raised
                styleColor: Qt.alpha(Colours.m3Colors.m3Scrim, 0.5)
                text: `(${lineDelegate.modelData.translation})`
                visible: lineDelegate.modelData.translation !== ""
                width: parent.width
                wrapMode: Text.Wrap
                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                    }
                }

                font {
                    family: "Noto Sans"
                    hintingPreference: Font.PreferNoHinting
                    kerning: true
                    pixelSize: Appearance.fonts.size.normal
                    preferShaping: true
                    weight: Font.DemiBold
                }
            }
        }
        onCurrentIndexChanged: {
            if (currentIndex < 0)
                positionViewAtBeginning();
            else
                positionViewAtIndex(currentIndex, ListView.Center);
        }

        Connections {

            function onLinesChanged() {
                listView.positionViewAtBeginning();
            }

            target: Lyrics
        }
    }
}
