pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Vast.Lyrics
import Vast.Utils

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Widgets

RowLayout {
    id: root

    property var trackArtColors: TrackArt.colors

    function cleanDesktopEntry(entry: string): string {
        if (!entry || entry === "No Player")
            return entry;
        const parts = entry.split(".");
        const name = parts[parts.length - 1];
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    spacing: Appearance.spacing.small

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: Appearance.margin.normal

        Loader {
            active: true
            anchors.fill: parent
            asynchronous: false
            enabled: !Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 0 : 1
            scale: Configs.mediaPlayer.showLyrics ? 0.96 : 1
            sourceComponent: playerControls

            Behavior on opacity {
                NAnim {
                }
            }
            Behavior on scale {
                NAnim {
                }
            }
        }
        Loader {
            active: true
            anchors.fill: parent
            asynchronous: false
            enabled: Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 1 : 0
            scale: Configs.mediaPlayer.showLyrics ? 1 : 0.96
            sourceComponent: lyricsControls

            Behavior on opacity {
                NAnim {
                }
            }
            Behavior on scale {
                NAnim {
                }
            }
        }
    }
    Component {
        id: lyricsControls

        RowLayout {
            spacing: Appearance.spacing.large

            Component.onCompleted: {
                if (LyricsProvider.currentLineIndex < 0)
                    lyricsView.listView.positionViewAtBeginning();
                else
                    lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignLeft
                Layout.leftMargin: Appearance.margin.small
                implicitHeight: parent.height
                implicitWidth: parent.width * 0.5

                ClippingRectangle {
                    Layout.alignment: Qt.AlignCenter
                    implicitHeight: 60
                    implicitWidth: 60
                    radius: Appearance.rounding.full

                    Image {
                        id: trackArt

                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
                        sourceSize: Qt.size(60, 60)

                        Behavior on opacity {
                            NAnim {
                            }
                        }
                    }
                }
                Wavy {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0

                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                    FrameAnimation {
                        running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing

                        onTriggered: Players.active.positionChanged()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.large

                    StyledText {
                        color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        text: Players.active?.trackArtist ?? ""
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        text: Players.active == null ? "0:00" : `${FormatTimeUtils.formatDuration(Players.active?.position)} / ${FormatTimeUtils.formatDuration(Players.active?.length)}`

                        Timer {
                            interval: 1000
                            repeat: true
                            running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing

                            onTriggered: Players.active.positionChanged()
                        }
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    spacing: Appearance.spacing.normal

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        icon.name: "discover_tune"
                        icon.size: Appearance.fonts.size.large
                        implicitHeight: 18
                        implicitWidth: 18

                        onClicked: Configs.mediaPlayer.showLyrics = false
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        enabled: Players.active?.shuffleSupported
                        icon.color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        icon.size: Appearance.fonts.size.large
                        implicitHeight: 18
                        implicitWidth: 18

                        onClicked: {
                            if (Players.active)
                                Players.active.shuffle = !Players.active.shuffle;
                        }
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        icon.name: "skip_previous"
                        icon.size: Appearance.fonts.size.extraLarge
                        implicitHeight: 22
                        implicitWidth: 22

                        onClicked: Players.active?.previous()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        icon.name: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        icon.size: Appearance.fonts.size.extraLarge
                        implicitHeight: 32
                        implicitWidth: 32

                        onClicked: Players.active?.togglePlaying()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        icon.name: "skip_next"
                        icon.size: Appearance.fonts.size.extraLarge
                        implicitHeight: 22
                        implicitWidth: 22

                        onClicked: Players.active?.next()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        enabled: Players.active?.loopSupported
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        implicitHeight: 18
                        implicitWidth: 18

                        onClicked: {
                            if (!Players.active)
                                return;
                            switch (Players.active.loopState) {
                            case MprisLoopState.None:
                                Players.active.loopState = MprisLoopState.Playlist;
                                break;
                            case MprisLoopState.Playlist:
                                Players.active.loopState = MprisLoopState.Track;
                                break;
                            case MprisLoopState.Track:
                                Players.active.loopState = MprisLoopState.None;
                                break;
                            }
                        }
                    }
                }
            }
            Connections {
                function onPositionChanged() {
                    LyricsProvider.setPlayback(Players.active.position, Players.active.rate, Players.active.isPlaying);
                }
                function onPostTrackChanged() {
                    if (LyricsProvider.currentLineIndex < 0)
                        lyricsView.listView.positionViewAtBeginning();
                    else
                        lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
                }
                function onTrackChanged() {
                    if (LyricsProvider.currentLineIndex < 0) {
                        LyricsProvider.fetch(Players.active.trackTitle, Players.active.trackArtist, Players.active.length);
                        lyricsView.listView.positionViewAtBeginning();
                    } else
                        lyricsView.listView.positionViewAtIndex(LyricsProvider.currentLineIndex, ListView.Center);
                }

                target: Players.active
            }
            LyricsView {
                id: lyricsView

                Layout.alignment: Qt.AlignRight
                Layout.rightMargin: Appearance.margin.small
                activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                implicitHeight: parent.height
                implicitWidth: parent.width * 0.4
                inactiveColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.tertiary : Colours.m3Colors.m3Tertiary
            }
        }
    }
    Component {
        id: playerControls

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            spacing: Appearance.spacing.small

            Behavior on opacity {
                NAnim {
                }
            }

            StyledText {
                Layout.fillWidth: true
                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: Players.active?.trackTitle ?? ""
                wrapMode: Text.NoWrap
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    text: Players.active?.trackArtist ?? ""
                }
                Item {
                    Layout.fillWidth: true
                }
                StyledText {
                    color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    text: Players.active == null ? "0:00" : `${FormatTimeUtils.formatDuration(Players.active?.position)} / ${FormatTimeUtils.formatDuration(Players.active?.length)}`

                    Timer {
                        interval: 1000
                        repeat: true
                        running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing

                        onTriggered: Players.active.positionChanged()
                    }
                }
            }
            Wavy {
                Layout.fillWidth: true
                activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
                implicitWidth: 28
                value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0

                onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                FrameAnimation {
                    running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing

                    onTriggered: Players.active.positionChanged()
                }
            }
            Item {
                Layout.fillWidth: true
                implicitHeight: controlsRow.implicitHeight

                RowLayout {
                    id: controlsRow

                    anchors.centerIn: parent
                    spacing: Appearance.spacing.small

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        enabled: LyricsProvider.state === LyricsProvider.State.Ready
                        icon.color: enabled ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant)
                        icon.name: "lyrics"
                        icon.size: Appearance.fonts.size.larger
                        implicitHeight: 24
                        implicitWidth: 24

                        onClicked: {
                            if (LyricsProvider.state === LyricsProvider.State.Ready)
                                Configs.mediaPlayer.showLyrics = true;
                        }
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        enabled: Players.active?.shuffleSupported
                        icon.color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        icon.size: Appearance.fonts.size.larger
                        implicitHeight: 24
                        implicitWidth: 24

                        onClicked: {
                            if (Players.active)
                                Players.active.shuffle = !Players.active.shuffle;
                        }
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        icon.name: "skip_previous"
                        icon.size: Appearance.fonts.size.extraLarge
                        implicitHeight: 32
                        implicitWidth: 32

                        onClicked: Players.active?.previous()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        icon.name: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        icon.size: Appearance.fonts.size.extraLarge * 1.2
                        implicitHeight: 36
                        implicitWidth: 36

                        onClicked: Players.active?.togglePlaying()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        icon.color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                        icon.name: "skip_next"
                        icon.size: Appearance.fonts.size.extraLarge
                        implicitHeight: 32
                        implicitWidth: 32

                        onClicked: Players.active?.next()
                    }
                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        color: "transparent"
                        enabled: Players.active?.loopSupported
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        implicitHeight: 24
                        implicitWidth: 24

                        onClicked: {
                            if (!Players.active)
                                return;
                            switch (Players.active.loopState) {
                            case MprisLoopState.None:
                                Players.active.loopState = MprisLoopState.Playlist;
                                break;
                            case MprisLoopState.Playlist:
                                Players.active.loopState = MprisLoopState.Track;
                                break;
                            case MprisLoopState.Track:
                                Players.active.loopState = MprisLoopState.None;
                                break;
                            }
                        }
                    }
                }
                ComboBox {
                    id: playerComboBox

                    model: Players.players
                    textRole: "desktopMenu"

                    background: StyledRect {
                        color: "transparent"
                        implicitHeight: 28
                        implicitWidth: 140
                    }
                    contentItem: Row {
                        leftPadding: Appearance.padding.normal
                        spacing: Appearance.spacing.small

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            asynchronous: true
                            implicitHeight: 20
                            implicitWidth: 20
                            source: Players.active?.desktopEntry === "" ? Quickshell.iconPath("helium", "image-missing") : IconUtils.iconForId(Players.active.desktopEntry)
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.large
                            maximumLineCount: 1
                            text: Players.active?.desktopEntry === "" ? "Helium" : root.cleanDesktopEntry(Players.active?.desktopEntry) ?? "No Player"
                            width: 100
                        }
                    }
                    delegate: ItemDelegate {
                        id: playerDelegate

                        required property int index
                        required property MprisPlayer modelData

                        highlighted: playerComboBox.highlightedIndex === index
                        width: playerComboBox.popup.width

                        background: StyledRect {
                            id: itemBg

                            property real colorBlendProgress: 1.0
                            property bool colorBlending: false
                            property color colorFrom
                            property color colorTo
                            property color target: (playerComboBox.currentIndex === playerDelegate.index || playerDelegate.highlighted) ? Qt.alpha(Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary, 0.18) : "transparent"

                            height: parent.height
                            radius: Appearance.rounding.normal

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
                            onTargetChanged: {
                                colorBlendAnim.stop();
                                colorFrom = color;
                                colorTo = target;
                                colorBlending = true;
                                colorBlendProgress = 0.0;
                                colorBlendAnim.start();
                            }

                            anchors {
                                left: parent.left
                                margins: Appearance.margin.small
                                right: parent.right
                            }
                            NAnim {
                                id: colorBlendAnim

                                duration: Appearance.animations.durations.small
                                from: 0.0
                                property: "colorBlendProgress"
                                target: itemBg
                                to: 1.0
                            }
                            SimpleRipple {
                                anchors.fill: parent
                                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                                xClipRadius: itemBg.radius
                                yClipRadius: itemBg.radius
                            }
                        }
                        contentItem: Row {
                            spacing: Appearance.spacing.normal

                            anchors {
                                left: parent.left
                                leftMargin: Appearance.margin.large
                                right: parent.right
                                rightMargin: Appearance.margin.large
                                verticalCenter: parent.verticalCenter
                            }
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                asynchronous: true
                                implicitHeight: 20
                                implicitWidth: 20
                                source: IconUtils.iconForId(playerDelegate.modelData.desktopEntry)
                            }
                            StyledText {
                                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: playerComboBox.currentIndex === playerDelegate.index ? Font.Medium : Font.Normal
                                text: root.cleanDesktopEntry(playerDelegate.modelData.desktopEntry) ?? ""
                            }
                        }

                        onClicked: {
                            playerComboBox.currentIndex = index;
                            Players.index = index;
                            playerComboBox.popup.close();
                        }
                    }
                    popup: Popup {
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        padding: 0
                        width: 220
                        x: playerComboBox.width - width
                        y: playerComboBox.height + 4

                        background: StyledRect {
                            color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.surfaceVariant : Colours.m3Colors.m3SurfaceVariant
                            radius: Appearance.rounding.large

                            Elevation {
                                anchors.fill: parent
                                level: 2
                                radius: parent.radius - 2
                                z: -1
                            }
                        }
                        contentItem: ListView {
                            id: listView

                            cacheBuffer: 0
                            clip: true
                            currentIndex: playerComboBox.currentIndex
                            implicitHeight: Math.min(contentHeight, 320)
                            model: playerComboBox.delegateModel

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }
                            footer: Item {
                                height: 8
                            }
                            header: Item {
                                height: 8
                            }
                        }
                        enter: Transition {
                            NAnim {
                                duration: Appearance.animations.durations.small
                                from: 0
                                property: "opacity"
                                to: 1
                            }
                            NAnim {
                                duration: Appearance.animations.durations.small
                                from: 0.95
                                property: "scale"
                                to: 1
                            }
                        }
                        exit: Transition {
                            NAnim {
                                duration: Appearance.animations.durations.small
                                from: 1
                                property: "opacity"
                                to: 0
                            }
                        }
                    }

                    onActivated: index => {
                        currentIndex = index;
                        Players.index = index;
                        const player = Players.players[index];
                        LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
                    }

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
