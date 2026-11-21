pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Base.DrawerComponents
import qs.Components.Button
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Scope {
    id: root

    required property ShellScreen monitor
    required property real        targetX
    required property bool        triggerHovered

    readonly property real        barBottom: (Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0) + Configs.bar.barHeight
    readonly property real        boardHeight: root.lyricsVisible ? 268 : 180
    readonly property real        boardWidth: 336
    readonly property color       dynOnPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onPrimary : Colours.m3Colors.m3OnPrimary
    readonly property color       dynOnSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurface : Colours.m3Colors.m3OnSurface
    readonly property color       dynOnSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.onSurfaceVariant : Colours.m3Colors.m3OnSurfaceVariant
    readonly property color       dynOutline: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.outline : Colours.m3Colors.m3Outline
    readonly property color       dynPrimary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.primary : Colours.m3Colors.m3Primary
    readonly property color       dynSurface: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surface : Colours.m3Colors.m3Surface
    readonly property color       dynSurfaceVariant: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.surfaceVariant : Colours.m3Colors.m3SurfaceVariant
    readonly property color       dynTertiary: Configs.mediaPlayer.dynamicColorsCover ? trackArtColors.tertiary : Colours.m3Colors.m3Tertiary
    readonly property bool        lyricsVisible: Lyrics.lines.length > 0
    readonly property real        maxBoardHeight: 280
    readonly property bool        showing: Players.active !== null && (root.triggerHovered || root.pointerInside || root.grace)

    property bool                 grace: false
    property bool                 mapped: false
    property bool                 pointerInside: false
    property var                  trackArtColors: TrackArt.colors

    onShowingChanged: {
        if (root.showing) {
            hideTimer.stop();
            root.mapped = true;
            Lyrics.syncPlayback();
        } else {
            hideTimer.restart();
        }
    }
    onTriggerHoveredChanged: {
        if (root.triggerHovered) {
            closeTimer.stop();
            root.grace = false;
        } else {
            closeTimer.restart();
            root.grace = true;
        }
    }

    Timer {
        id: closeTimer

        interval: Appearance.animations.durations.small
        onTriggered: {
            root.pointerInside = false;
            root.grace         = false;
        }
    }

    Timer {
        id: hideTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.mapped = false
    }

    LazyLoader {
        id: previewLoader

        activeAsync: root.showing || root.mapped
        component: PanelWindow {
            id: panelWindow

            BackgroundEffect.blurRegion: regionContent
            HyprlandWindow.visibleMask: regionContent
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: LayerNamespaces.drawers
            aboveWindows: false
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: root.maxBoardHeight
            margins.top: root.barBottom // qmllint disable
            mask: regionContent
            screen: root.monitor
            Component.onCompleted: boardHost.armAnimations()
            onWidthChanged: boardHost.armAnimations()

            Region {
                id: regionContent

                item: board.visible ? boardHost : null
            }

            anchors {
                left: true
                right: true
                top: true
            }

            Item {
                id: boardHost

                readonly property real screenWidth: root.monitor ? root.monitor.width : panelWindow.width

                property bool          animateX: false
                property bool          openReady: false

                // Defer arming until after initial layout/configure so Drawer starts at
                // depth 0 and animates down on open without sliding x from 0.
                function               armAnimations(): void {
                    if (openReady || board.width <= 0 || panelWindow.width < screenWidth - 1)
                        return;
                    Qt.callLater(() => {
                        if (panelWindow.width >= boardHost.screenWidth - 1 && root.mapped) {
                            boardHost.openReady = true;
                            boardHost.animateX  = true;
                        }
                    });
                }

                height: board.height
                visible: panelWindow.width >= screenWidth - 1 && panelWindow.height > 0
                width: board.width
                x: Math.round(root.targetX - board.width / 2)
                y: 0
                Behavior on x {
                    enabled: boardHost.animateX && root.mapped

                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }

                Drawer {
                    id: board

                    alignment: Qt.AlignHCenter
                    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
                    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    color: GlobalStates.drawerColors
                    cornerRadius: Appearance.rounding.normal
                    depth: root.boardHeight
                    edge: Qt.TopEdge
                    filletRadius: 40
                    length: root.boardWidth
                    open: boardHost.openReady && root.showing
                    onWidthChanged: boardHost.armAnimations()

                    HoverHandler {
                        onHoveredChanged: {
                            root.pointerInside = hovered;
                            if (hovered) {
                                closeTimer.stop();
                                root.grace = false;
                            } else {
                                closeTimer.restart();
                                root.grace = true;
                            }
                        }
                    }

                    Loader {
                        active: root.showing || root.mapped || board.visible
                        anchors.fill: parent
                        sourceComponent: Item {
                            height: root.boardHeight
                            width: root.boardWidth

                            ColumnLayout {
                                id: popupLayout

                                spacing: Appearance.spacing.small
                                Component.onCompleted: Lyrics.syncPlayback()

                                anchors {
                                    fill: parent
                                    margins: Appearance.margin.normal
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.normal

                                    ClippingWrapperRectangle {
                                        color: "transparent"
                                        implicitHeight: 48
                                        implicitWidth: 48
                                        radius: Appearance.rounding.normal

                                        Item {
                                            implicitHeight: 48
                                            implicitWidth: 48

                                            Icon {
                                                anchors.centerIn: parent
                                                color: root.dynOnSurface
                                                font.pixelSize: Appearance.fonts.size.extraLarge
                                                icon: "music_note"
                                                visible: TrackArt.cachedPath === ""
                                            }

                                            Image {
                                                anchors.fill: parent
                                                asynchronous: true
                                                cache: false
                                                fillMode: Image.PreserveAspectCrop
                                                source: TrackArt.cachedPath.startsWith("/") ? "file://" + TrackArt.cachedPath : TrackArt.cachedPath
                                                sourceSize: Qt.size(96, 96)
                                                visible: TrackArt.cachedPath !== ""
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            Layout.fillWidth: true
                                            color: root.dynOnSurface
                                            elide: Text.ElideRight
                                            font.pixelSize: Appearance.fonts.size.normal
                                            font.weight: Font.DemiBold
                                            text: Players.active?.trackTitle ?? ""
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            color: root.dynOnSurfaceVariant
                                            elide: Text.ElideRight
                                            font.pixelSize: Appearance.fonts.size.small
                                            text: Players.active?.trackArtist ?? ""
                                        }
                                    }
                                }

                                Wavy {
                                    Layout.fillWidth: true
                                    active: root.showing
                                    activeColor: root.dynPrimary
                                    enableWave: Players.active?.playbackState === MprisPlaybackState.Playing
                                    implicitHeight: 24
                                    inactiveColor: root.dynSurfaceVariant
                                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.boundedPosition(Players.active) / Players.active.length : 0
                                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                                    FrameAnimation {
                                        running: root.showing && Players.active?.playbackState === MprisPlaybackState.Playing
                                        onTriggered: Players.active.positionChanged()
                                    }
                                }

                                LyricsView {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    active: root.showing && root.lyricsVisible
                                    activeColor: Colours.m3Colors.m3OnBackground
                                    activeFontSize: Appearance.fonts.size.normal
                                    horizontalAlignment: Text.AlignHCenter
                                    inactiveColor: Qt.alpha(Colours.m3Colors.m3OnBackground, 0.45)
                                    inactiveFontSize: Appearance.fonts.size.small
                                    raised: false
                                    spacing: 4
                                    visible: root.lyricsVisible
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignCenter
                                    spacing: Appearance.spacing.small

                                    FloatingButton {
                                        backgroundRadius: Appearance.rounding.normal
                                        color: "transparent"
                                        enabled: Players.active?.shuffleSupported ?? false
                                        icon.color: Players.active?.shuffle ? root.dynPrimary : root.dynOutline
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
                                        icon.color: root.dynOnSurface
                                        icon.name: "skip_previous"
                                        icon.size: Appearance.fonts.size.extraLarge
                                        implicitHeight: 32
                                        implicitWidth: 32
                                        onClicked: Players.active?.previous()
                                    }

                                    FloatingButton {
                                        backgroundRadius: Appearance.rounding.normal
                                        color: "transparent"
                                        icon.color: root.dynOnSurface
                                        icon.name: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                                        icon.size: Appearance.fonts.size.extraLarge
                                        implicitHeight: 32
                                        implicitWidth: 32
                                        onClicked: Players.active?.togglePlaying()
                                    }

                                    FloatingButton {
                                        backgroundRadius: Appearance.rounding.normal
                                        color: "transparent"
                                        icon.color: root.dynOnSurface
                                        icon.name: "skip_next"
                                        icon.size: Appearance.fonts.size.extraLarge
                                        implicitHeight: 32
                                        implicitWidth: 32
                                        onClicked: Players.active?.next()
                                    }

                                    FloatingButton {
                                        backgroundRadius: Appearance.rounding.normal
                                        color: "transparent"
                                        enabled: Players.active?.loopSupported ?? false
                                        icon.color: Players.active?.loopState !== MprisLoopState.None ? root.dynPrimary : root.dynOutline
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
                }
            }
        }
    }
}
