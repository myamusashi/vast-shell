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

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);

        if (hours > 0)
            return hours + ":" + minutes.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0');

        return minutes + ":" + secs.toString().padStart(2, '0');
    }

    RowLayout {
        id: mediaInfo

        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        RowLayout {
            Repeater {
                model: [
                    {
                        icon: "skip_previous",
                        clicked: () => Players.active?.previous()
                    },
                    {
                        icon: Players.active === null ? "question_mark" : Players.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle",
                        clicked: () => Players.active?.togglePlaying()
                    },
                    {
                        icon: "skip_next",
                        clicked: () => Players.active?.next()
                    }
                ]
                delegate: Icon {
                    required property var modelData

                    icon: modelData.icon
                    font.pixelSize: Appearance.fonts.size.large * 1.4
                    color: Colours.m3Colors.m3OnBackground

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: parent.modelData.clicked()
                    }
                }
            }
        }

        StyledText {
            text: Players.active === null ? "null" : Players.active.trackArtist
            color: Colours.m3Colors.m3OnBackground
            font.weight: Font.DemiBold
        }
    }
}
