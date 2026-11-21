pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    readonly property real positionMs: Lyrics.positionMs

    property bool          active: visible
    property color         activeColor: Colours.m3Colors.m3Primary
    property real          activeFontSize: Appearance.fonts.size.large
    property int           horizontalAlignment: Text.AlignLeft
    property color         inactiveColor: Colours.m3Colors.m3Secondary
    property real          inactiveFontSize: Appearance.fonts.size.normal
    property alias         listView: listView
    property bool          raised: true
    property real          spacing: 16

    Component.onCompleted: Lyrics.setPositionConsumerActive(root, root.active)
    Component.onDestruction: Lyrics.setPositionConsumerActive(root, false)
    onActiveChanged: Lyrics.setPositionConsumerActive(root, root.active)

    ListView {
        id: listView

        anchors.fill: parent
        cacheBuffer: 200
        clip: true
        currentIndex: Lyrics.currentLineIndex
        model: Lyrics.lines
        spacing: root.spacing
        delegate: Column {
            id: lineDelegate

            required property int  index
            required property var  modelData

            readonly property bool isActiveLine: index === Lyrics.currentLineIndex

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

            AnimatedLyricLabel {
                id: lyricText

                active: lineDelegate.isActiveLine
                activeColor: root.activeColor
                font.pixelSize: root.activeFontSize
                horizontalAlignment: root.horizontalAlignment
                inactiveColor: root.inactiveColor
                positionMs: root.positionMs
                raised: root.raised
                synced: Lyrics.synced
                text: lineDelegate.modelData.text
                width: parent.width
                words: lineDelegate.modelData.words ?? []
                wrapMode: Text.Wrap
            }

            StyledText {
                id: translationText

                color: lineDelegate.isActiveLine ? root.activeColor : root.inactiveColor
                font.pixelSize: root.inactiveFontSize
                horizontalAlignment: root.horizontalAlignment
                opacity: 0.7
                style: root.raised ? Text.Raised : Text.Normal
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
