pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import AnotherRipple
import Vast.Lyrics
import Vast.Utils

import qs.Core.Configs
import qs.Core.Utils
import qs.Core.States
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Components.Tooltip
import qs.Widgets

RowLayout {
    id: root

    property var trackArtColors: TrackArt.colors

    function     cleanDesktopEntry(entry: string): string {
        if (!entry || entry === "No Player")
            return entry;
        const parts = entry.split(".");
        const name  = parts[parts.length - 1];
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function     playerName(player: MprisPlayer): string {
        if (!player)
            return "No Player";
        if (player.desktopEntry)
            return DesktopEntries.heuristicLookup(player.desktopEntry)?.name || root.cleanDesktopEntry(player.desktopEntry);
        if (player.identity)
            return player.identity;
        const dbusPrefix = "org.mpris.MediaPlayer2.";
        if (player.dbusName && player.dbusName.startsWith(dbusPrefix)) {
            const service = player.dbusName.slice(dbusPrefix.length).replace(/\.instance\d+$/, "");
            if (service)
                return root.cleanDesktopEntry(service);
        }
        return "Unknown Player";
    }

    spacing: Appearance.spacing.small

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: Appearance.margin.normal

        Loader {
            id: playerControlsLoader

            active: !Configs.mediaPlayer.showLyrics || opacity > 0
            anchors.fill: parent
            asynchronous: false
            enabled: !Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 0 : 1
            scale: Configs.mediaPlayer.showLyrics ? 0.96 : 1
            sourceComponent: playerControls
            Behavior on opacity {
                NAnim {}
            }
            Behavior on scale {
                NAnim {}
            }
        }

        Loader {
            id: lyricsControlsLoader

            active: Configs.mediaPlayer.showLyrics || opacity > 0
            anchors.fill: parent
            asynchronous: false
            enabled: Configs.mediaPlayer.showLyrics
            opacity: Configs.mediaPlayer.showLyrics ? 1 : 0
            scale: Configs.mediaPlayer.showLyrics ? 1 : 0.96
            sourceComponent: lyricsControls
            Behavior on opacity {
                NAnim {}
            }
            Behavior on scale {
                NAnim {}
            }
        }
    }

    Component {
        id: lyricsControls

        RowLayout {
            spacing: Appearance.spacing.large
            Component.onCompleted: {
                Lyrics.syncPlayback();
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
                            NAnim {}
                        }
                    }
                }

                Wavy {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 10
                    active: GlobalStates.isQuickSettingsOpen
                    activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                    enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.boundedPosition(Players.active) / Players.active.length : 0
                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.large

                    StyledText {
                        id: lyricsArtistText

                        color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        text: Players.active?.trackArtist ?? ""

                        Tooltip {
                            anchorItem: lyricsArtistText
                            enabled: lyricsArtistText.truncated
                            text: lyricsArtistText.text
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        text: Players.active == null ? "0:00" : `${FormatTimeUtils.formatDuration(Players.boundedPosition(Players.active))} / ${FormatTimeUtils.formatDuration(Players.active?.length)}`

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
                        tooltipText: qsTr("Hide lyrics")
                        onClicked: Configs.mediaPlayer.showLyrics = false
                    }

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        buttonEnabled: Boolean(Players.active?.shuffleSupported)
                        color: "transparent"
                        disabledTooltipText: qsTr("Shuffle not supported by player")
                        icon.color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        icon.size: Appearance.fonts.size.large
                        implicitHeight: 18
                        implicitWidth: 18
                        tooltipText: Players.active?.shuffle ? qsTr("Disable shuffle") : qsTr("Enable shuffle")
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
                        tooltipText: qsTr("Previous track")
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
                        tooltipText: Players.active?.playbackState === MprisPlaybackState.Playing ? qsTr("Pause") : qsTr("Play")
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
                        tooltipText: qsTr("Next track")
                        onClicked: Players.active?.next()
                    }

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        buttonEnabled: Boolean(Players.active?.loopSupported)
                        color: "transparent"
                        disabledTooltipText: qsTr("Repeat not supported by player")
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        implicitHeight: 18
                        implicitWidth: 18
                        tooltipText: Players.active?.loopState === MprisLoopState.Playlist ? qsTr("Repeat: Playlist") : Players.active?.loopState === MprisLoopState.Track ? qsTr("Repeat: Track") : qsTr("Repeat: Off")
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
                NAnim {}
            }

            StyledText {
                id: playerTrackTitle

                Layout.fillWidth: true
                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: Players.active?.trackTitle ?? ""
                wrapMode: Text.NoWrap

                Tooltip {
                    anchorItem: playerTrackTitle
                    enabled: playerTrackTitle.truncated
                    text: playerTrackTitle.text
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    id: playerArtistText

                    color: Configs.mediaPlayer.dynamicColorsCover ? Qt.alpha(root.trackArtColors.onSurface, 0.8) : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.8)
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    text: Players.active?.trackArtist ?? ""

                    Tooltip {
                        anchorItem: playerArtistText
                        enabled: playerArtistText.truncated
                        text: playerArtistText.text
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    text: Players.active == null ? "0:00" : `${FormatTimeUtils.formatDuration(Players.boundedPosition(Players.active))} / ${FormatTimeUtils.formatDuration(Players.active?.length)}`

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
                active: GlobalStates.isQuickSettingsOpen
                activeColor: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary
                enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
                implicitWidth: 28
                value: Players.active === null ? 0 : Players.active.length > 0 ? Players.boundedPosition(Players.active) / Players.active.length : 0
                onMoved: Players.active ? Players.active.position = value * Players.active.length : {}
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
                        buttonEnabled: LyricsProvider.state === LyricsProvider.State.Ready
                        color: "transparent"
                        disabledTooltipText: LyricsProvider.state === LyricsProvider.State.Loading ? qsTr("Loading lyrics…") : qsTr("Lyrics unavailable")
                        icon.color: LyricsProvider.state === LyricsProvider.State.Ready ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant)
                        icon.name: "lyrics"
                        icon.size: Appearance.fonts.size.larger
                        implicitHeight: 24
                        implicitWidth: 24
                        tooltipText: qsTr("Show lyrics")
                        onClicked: {
                            if (LyricsProvider.state === LyricsProvider.State.Ready)
                                Configs.mediaPlayer.showLyrics = true;
                        }
                    }

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        buttonEnabled: Boolean(Players.active?.shuffleSupported)
                        color: "transparent"
                        disabledTooltipText: qsTr("Shuffle not supported by player")
                        icon.color: Players.active?.shuffleSupported || Players.active?.shuffle ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.shuffleSupported || Players.active?.shuffleSupported || Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        icon.size: Appearance.fonts.size.larger
                        implicitHeight: 24
                        implicitWidth: 24
                        tooltipText: Players.active?.shuffle ? qsTr("Disable shuffle") : qsTr("Enable shuffle")
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
                        tooltipText: qsTr("Previous track")
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
                        tooltipText: Players.active?.playbackState === MprisPlaybackState.Playing ? qsTr("Pause") : qsTr("Play")
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
                        tooltipText: qsTr("Next track")
                        onClicked: Players.active?.next()
                    }

                    FloatingButton {
                        backgroundRadius: Appearance.rounding.normal
                        buttonEnabled: Boolean(Players.active?.loopSupported)
                        color: "transparent"
                        disabledTooltipText: qsTr("Repeat not supported by player")
                        icon.color: Players.active?.loopSupported || (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary) : (Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.outline : Colours.m3Colors.m3Outline)
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        implicitHeight: 24
                        implicitWidth: 24
                        tooltipText: Players.active?.loopState === MprisLoopState.Playlist ? qsTr("Repeat: Playlist") : Players.active?.loopState === MprisLoopState.Track ? qsTr("Repeat: Track") : qsTr("Repeat: Off")
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

                    Tooltip {
                        anchorItem: playerComboBox
                        enabled: !playerComboBox.popup.visible
                        text: qsTr("Switch player (%1)").arg(root.playerName(Players.active))
                    }

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    currentIndex: Players.index
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
                            implicitHeight: 20
                            implicitWidth: 20
                            source: IconUtils.iconForPlayer(Players.active)
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.large
                            maximumLineCount: 1
                            text: root.playerName(Players.active)
                            width: 100
                        }
                    }
                    delegate: ItemDelegate {
                        id: playerDelegate

                        required property int         index
                        required property MprisPlayer modelData

                        highlighted: playerComboBox.highlightedIndex === index
                        width: playerComboBox.popup.width
                        background: StyledRect {
                            id: itemBg

                            property bool  colorBlending: false
                            property real  colorBlendProgress: 1.0
                            property color colorFrom
                            property color colorTo
                            property color target: {
                                const accent = Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.primary : Colours.m3Colors.m3Primary;
                                if (Players.index === playerDelegate.index)
                                    return Qt.alpha(accent, 0.18);
                                if (playerDelegate.highlighted)
                                    return Qt.alpha(accent, 0.08);
                                return "transparent";
                            }

                            anchors {
                                left: parent.left
                                margins: Appearance.margin.small
                                right: parent.right
                            }

                            height: parent.height
                            radius: Appearance.rounding.normal
                            onColorBlendProgressChanged: {
                                if (!colorBlending)
                                    return;
                                if (colorBlendProgress >= 1) {
                                    color         = colorTo;
                                    colorBlending = false;
                                } else if (colorBlendProgress > 0) {
                                    color = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress);
                                }
                            }
                            onTargetChanged: {
                                colorBlendAnim.stop();
                                colorFrom          = color;
                                colorTo            = target;
                                colorBlending      = true;
                                colorBlendProgress = 0.0;
                                colorBlendAnim.start();
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

                            anchors {
                                left: parent.left
                                leftMargin: Appearance.margin.large
                                right: parent.right
                                rightMargin: Appearance.margin.large
                                verticalCenter: parent.verticalCenter
                            }

                            spacing: Appearance.spacing.normal

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitHeight: 20
                                implicitWidth: 20
                                source: IconUtils.iconForPlayer(playerDelegate.modelData)
                            }

                            StyledText {
                                color: Configs.mediaPlayer.dynamicColorsCover ? root.trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fonts.size.normal
                                font.weight: Players.index === playerDelegate.index ? Font.Medium : Font.Normal
                                text: root.playerName(playerDelegate.modelData)
                            }
                        }
                        onClicked: {
                            Players.manualIndex = index;
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
                            currentIndex: Players.index
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
                        Players.manualIndex = index;
                        const player        = Players.players[index];
                        if (player)
                            LyricsProvider.fetch(player.trackTitle, player.trackArtist, player.length);
                    }
                }
            }
        }
    }
}
