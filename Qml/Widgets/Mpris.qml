pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    id: mprisRoot

    readonly property int    activeLineIndex: Lyrics.currentLineIndex
    readonly property int    index: 0
    readonly property string liveLyric: {
        if (!Players.active || !Lyrics.synced || !Lyrics.lines)
            return "";
        const idx = Lyrics.currentLineIndex;
        if (idx < 0 || idx >= Lyrics.lines.length)
            return "";
        return (Lyrics.lines[idx]?.text ?? "").trim();
    }
    readonly property bool   positionActive: visible && displayedLyric !== ""
    readonly property real   positionMs: Lyrics.positionMs

    property string          displayedLyric: ""

    color: "transparent"
    implicitHeight: parent.height
    implicitWidth: rowButton.implicitWidth + (artistText.visible ? Appearance.spacing.small + artistText.width : 0)
    Component.onCompleted: {
        displayedLyric = liveLyric;
        Lyrics.setPositionConsumerActive(mprisRoot, positionActive);
    }
    Component.onDestruction: Lyrics.setPositionConsumerActive(mprisRoot, false)
    onLiveLyricChanged: {
        if (liveLyric === displayedLyric)
            return;
        if (displayedLyric === "" || liveLyric === "") {
            lyricScrollAnim.stop();
            outgoingLyric.visible = false;
            incomingLyric.y       = 0;
            incomingLyric.opacity = 1;
            displayedLyric        = liveLyric;
            return;
        }
        outgoingLyric.text    = displayedLyric;
        outgoingLyric.y       = 0;
        outgoingLyric.opacity = 1;
        outgoingLyric.visible = true;
        displayedLyric        = liveLyric;
        lyricScrollAnim.restart();
    }
    onPositionActiveChanged: Lyrics.setPositionConsumerActive(mprisRoot, positionActive)

    FontMetrics {
        id: lyricsMetrics

        font: incomingLyric.font
    }

    Item {
        id: lyricsBox

        anchors {
            right: rowButton.left
            rightMargin: Appearance.spacing.small
            verticalCenter: rowButton.verticalCenter
        }

        clip: true
        height: 20
        visible: mprisRoot.displayedLyric !== ""
        width: mprisRoot.displayedLyric !== "" ? lyricsMetrics.advanceWidth(mprisRoot.displayedLyric) + Appearance.padding.small : 0
        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        ParallelAnimation {
            id: lyricScrollAnim

            onFinished: outgoingLyric.visible = false

            NAnim {
                duration: Appearance.animations.durations.small
                from: 0
                property: "y"
                target: outgoingLyric
                to: -lyricsBox.height
            }

            NAnim {
                duration: Appearance.animations.durations.small
                from: 1
                property: "opacity"
                target: outgoingLyric
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.small
                from: lyricsBox.height
                property: "y"
                target: incomingLyric
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.small
                from: 0
                property: "opacity"
                target: incomingLyric
                to: 1
            }
        }

        StyledText {
            id: outgoingLyric

            color: Colours.m3Colors.m3OnBackground
            font.pixelSize: Appearance.fonts.size.small
            height: lyricsBox.height
            opacity: 0
            verticalAlignment: Text.AlignVCenter
            visible: false
            width: lyricsBox.width
        }

        AnimatedLyricLabel {
            id: incomingLyric

            active: true
            activeColor: Colours.m3Colors.m3OnBackground
            font.pixelSize: Appearance.fonts.size.small
            height: lyricsBox.height
            inactiveColor: Qt.alpha(Colours.m3Colors.m3OnBackground, 0.45)
            positionMs: mprisRoot.positionMs
            synced: Lyrics.synced
            text: mprisRoot.displayedLyric
            width: lyricsBox.width
            words: Lyrics.wordLines[mprisRoot.activeLineIndex]?.words ?? []
            wrapMode: Text.NoWrap
            y: 0
        }
    }

    RowButton {
        id: rowButton

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }

        contentColor: Colours.m3Colors.m3OnSecondaryContainer
        containerColor: Colours.m3Colors.m3SecondaryContainer
        model: [
            {
                icon: "skip_previous",
                tooltip: qsTr("Previous track")
            },
            {
                icon: Players.active === null ? "question_mark" : Players.active.playbackState === MprisPlaybackState.Playing ? "genres" : "play_circle",
                tooltip: Players.active === null ? qsTr("No active media player") : (Players.active.playbackState === MprisPlaybackState.Playing ? qsTr("Pause") : qsTr("Play"))
            },
            {
                icon: "skip_next",
                tooltip: qsTr("Next track")
            }
        ]
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
        id: artistText

        anchors {
            left: rowButton.right
            leftMargin: Appearance.spacing.small
            verticalCenter: rowButton.verticalCenter
        }

        color: Colours.m3Colors.m3OnBackground
        elide: Text.ElideRight
        font.pixelSize: Appearance.fonts.size.small
        font.weight: Font.DemiBold
        text: Players.active?.trackArtist ?? ""
        visible: text !== ""
        width: Math.min(implicitWidth, 160)

        Tooltip {
            anchorItem: artistText
            text: {
                if (!Players.active)
                    return "";
                return [Players.active.trackTitle, Players.active.trackArtist, Players.active.trackAlbum].filter(Boolean).join(" — ");
            }
        }
    }

    component RowButton: Row {
        id: root

        property int    buttonHeight: 20
        property int    buttonWidth: 24
        property color  containerColor
        property color  contentColor
        property real   disabledContainerOpacity: 0.10
        property real   disabledContentOpacity: 0.38
        property string iconFontFamily: "Material Symbols Rounded"
        property int    iconSize: 15
        property int    innerCornerRadius: 3
        property var    model: []

        signal          buttonClicked(int index)

        spacing: 1

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

                Tooltip {
                    anchorItem: button
                    text: button.modelData.tooltip ?? ""
                }
            }
        }
    }
}
