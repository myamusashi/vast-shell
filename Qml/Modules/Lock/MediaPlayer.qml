pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Components.Base
import qs.Components.Button
import qs.Services
import qs.Widgets

StyledRect {
    id: mediaPlayerRect

    readonly property color dynOnPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onPrimary : Colours.m3Colors.m3OnPrimary
    readonly property color dynOnSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
    readonly property color dynOnSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant
    readonly property color dynOutline: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.outline : Colours.m3Colors.m3Outline
    readonly property color dynPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.primary : Colours.m3Colors.m3Primary
    readonly property color dynSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surface : Colours.m3Colors.m3Surface
    readonly property color dynSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surfaceVariant : Colours.m3Colors.m3SurfaceVariant
    readonly property color dynTertiary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.tertiary : Colours.m3Colors.m3Tertiary

    property alias          mediaLayout: mediaColumnLayout
    property var            trackArtColors: TrackArt.colors

    Layout.alignment: Qt.AlignVCenter
    color: GlobalStates.drawerColors
    implicitHeight: mediaColumnLayout.implicitHeight + Appearance.margin.small * 2
    implicitWidth: Math.max(336, (mediaRow.implicitWidth + Appearance.margin.normal * 2) * 1.2)
    radius: Appearance.rounding.normal
    visible: Players.active !== null

    Elevation {
        anchors.fill: parent
        level: 1
        radius: parent.radius
    }

    ColumnLayout {
        id: mediaColumnLayout

        spacing: Appearance.spacing.small

        anchors {
            left: parent.left
            margins: Appearance.margin.small
            right: parent.right
            top: parent.top
        }

        RowLayout {
            id: mediaRow

            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            Item {
                implicitHeight: 28
                implicitWidth: 28

                Icon {
                    anchors.fill: parent
                    color: mediaPlayerRect.dynOnSurface
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "music_note"
                }

                Image {
                    anchors.fill: parent
                    asynchronous: true
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
                    sourceSize: Qt.size(48, 48)
                    visible: TrackArt.cachedPath !== ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    color: mediaPlayerRect.dynOnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    font.weight: Font.DemiBold
                    text: Players.active?.trackTitle ?? ""
                }

                StyledText {
                    Layout.fillWidth: true
                    color: mediaPlayerRect.dynOnSurfaceVariant
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    text: Players.active?.trackArtist ?? ""
                }
            }

            FloatingButton {
                backgroundRadius: Appearance.rounding.normal
                icon.color: mediaPlayerRect.dynSurface
                icon.name: "skip_previous"
                icon.size: Appearance.fonts.size.large
                implicitHeight: 24
                implicitWidth: 24
                onClicked: Players.active?.previous()
            }

            FloatingButton {
                backgroundRadius: Appearance.rounding.normal
                icon.color: mediaPlayerRect.dynSurface
                icon.name: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause" : "play_arrow"
                icon.size: Appearance.fonts.size.large
                implicitHeight: 24
                implicitWidth: 24
                onClicked: Players.active?.togglePlaying()
            }

            FloatingButton {
                backgroundRadius: Appearance.rounding.normal
                icon.color: mediaPlayerRect.dynSurface
                icon.name: "skip_next"
                icon.size: Appearance.fonts.size.large
                implicitHeight: 24
                implicitWidth: 24
                onClicked: Players.active?.next()
            }
        }

        Wavy {
            Layout.fillWidth: true
            activeColor: mediaPlayerRect.dynPrimary
            enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
            implicitHeight: 28
            inactiveColor: mediaPlayerRect.dynSurfaceVariant
            value: Players.active === null ? 0 : Players.active.length > 0 ? Players.boundedPosition(Players.active) / Players.active.length : 0
            onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

            FrameAnimation {
                running: Players.active?.playbackState === MprisPlaybackState.Playing
                onTriggered: Players.active.positionChanged()
            }
        }
    }

    HoverHandler {
        id: mediaHover

        cursorShape: Qt.PointingHandCursor
    }

    ClippingRectangle {
        id: mediaPopup

        property bool popupHovered: false

        anchors {
            bottom: mediaPlayerRect.top
            bottomMargin: Appearance.spacing.small
            horizontalCenter: parent.horizontalCenter
        }

        implicitWidth: parent.width
        implicitHeight: popupLayout.implicitHeight + Appearance.margin.normal * 2
        clip: true
        color: mediaPlayerRect.dynSurface
        opacity: mediaHover.hovered || popupHovered ? 1 : 0
        radius: Appearance.rounding.normal
        scale: mediaHover.hovered || popupHovered ? 1 : 0.92
        visible: opacity > 0
        onVisibleChanged: {
            if (visible)
                Lyrics.syncPlayback();
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.normal
            }
        }
        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }

        HoverHandler {
            onHoveredChanged: mediaPopup.popupHovered = hovered
        }

        Elevation {
            anchors.fill: parent
            level: 3
            radius: parent.radius
        }

        Image {
            id: popupCoverArt

            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            layer.enabled: true
            source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
            sourceSize: Qt.size(360, 200)
            visible: !!Players.active?.trackArtUrl
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blur: 1.0
                blurEnabled: true
                blurMax: Configs.generals.coverBlurRadius
            }
        }

        Rectangle {
            anchors.fill: parent
            color: mediaPlayerRect.dynSurface
            opacity: 0.82
        }

        ColumnLayout {
            id: popupLayout

            spacing: Appearance.spacing.small
            Component.onCompleted: Lyrics.syncPlayback()

            anchors {
                fill: parent
                margins: Appearance.margin.normal
            }

            RowLayout {
                spacing: Appearance.spacing.normal

                ClippingWrapperRectangle {
                    color: "transparent"
                    implicitHeight: 48
                    implicitWidth: 48
                    radius: Appearance.rounding.normal

                    Image {
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
                        sourceSize: Qt.size(96, 96)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        color: mediaPlayerRect.dynOnSurface
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        text: Players.active?.trackTitle ?? ""
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: mediaPlayerRect.dynOnSurfaceVariant
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.small
                        text: Players.active?.trackArtist ?? ""
                    }
                }
            }

            Wavy {
                Layout.fillWidth: true
                activeColor: mediaPlayerRect.dynPrimary
                enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
                implicitHeight: 24
                inactiveColor: mediaPlayerRect.dynSurfaceVariant
                value: Players.active === null ? 0 : Players.active.length > 0 ? Players.boundedPosition(Players.active) / Players.active.length : 0
                onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                FrameAnimation {
                    running: Players.active?.playbackState === MprisPlaybackState.Playing
                    onTriggered: Players.active.positionChanged()
                }
            }

            LyricsView {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                active: (mediaHover.hovered || mediaPopup.popupHovered) && mediaPopup.visible
                activeColor: Colours.m3Colors.m3OnBackground
                activeFontSize: Appearance.fonts.size.normal
                horizontalAlignment: Text.AlignHCenter
                inactiveColor: Qt.alpha(Colours.m3Colors.m3OnBackground, 0.45)
                inactiveFontSize: Appearance.fonts.size.small
                raised: false
                spacing: 4
                visible: Lyrics.lines.length > 0
            }

            RowLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: Appearance.spacing.small

                FloatingButton {
                    backgroundRadius: Appearance.rounding.normal
                    color: "transparent"
                    enabled: Players.active?.shuffleSupported
                    icon.color: Players.active?.shuffle ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOutline
                    icon.name: Players.active?.shuffle ? "shuffle_on" : "shuffle"
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
                    icon.color: mediaPlayerRect.dynOnSurface
                    icon.name: "skip_previous"
                    icon.size: Appearance.fonts.size.extraLarge
                    implicitHeight: 32
                    implicitWidth: 32
                    onClicked: Players.active?.previous()
                }

                FloatingButton {
                    backgroundRadius: Appearance.rounding.normal
                    color: "transparent"
                    icon.color: mediaPlayerRect.dynOnSurface
                    icon.name: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                    icon.size: Appearance.fonts.size.extraLarge
                    implicitHeight: 32
                    implicitWidth: 32
                    onClicked: Players.active?.togglePlaying()
                }

                FloatingButton {
                    backgroundRadius: Appearance.rounding.normal
                    color: "transparent"
                    icon.color: mediaPlayerRect.dynOnSurface
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
                    icon.color: Players.active?.loopState !== MprisLoopState.None ? mediaPlayerRect.dynPrimary : mediaPlayerRect.dynOutline
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
        }
    }
}
