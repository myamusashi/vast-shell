pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ClippingRectangle {
    id: root

    property url url: ""
    property var trackArtColors: {
        if (colorTrackArt.colors.length === 0)
            return {
                surface: "#1C1B1F",
                surfaceVariant: "#252337",
                primary: "#6750A4",
                accent: "#9C4FA3",
                onSurface: "#FFFFFF",
                secondary: "#E8DEF8",
                muted: "#CAC4D0",
                onPrimary: "#FFFFFF"
            };

        function toHex(color) {
            // QML color object → "#rrggbb" string
            const r = Math.round(color.r * 255).toString(16).padStart(2, '0');
            const g = Math.round(color.g * 255).toString(16).padStart(2, '0');
            const b = Math.round(color.b * 255).toString(16).padStart(2, '0');
            return `#${r}${g}${b}`;
        }

        function luminance(color) {
            return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
        }

        function saturation(color) {
            const max = Math.max(color.r, color.g, color.b);
            const min = Math.min(color.r, color.g, color.b);
            return max === 0 ? 0 : (max - min) / max;
        }

        const colors = Array.from(colorTrackArt.colors);
        const sorted = colors.slice().sort((a, b) => luminance(a) - luminance(b));
        const n = sorted.length;

        const midColors = sorted.slice(Math.floor(n * 0.3), Math.floor(n * 0.7));
        const primary = midColors.slice().sort((a, b) => saturation(b) - saturation(a))[0];

        return {
            surface: toHex(sorted[0]),
            surfaceVariant: toHex(sorted[Math.floor(n * 0.12)]),
            accent: toHex(sorted[Math.floor(n * 0.35)]),
            primary: toHex(primary),
            muted: toHex(sorted[Math.floor(n * 0.55)]),
            secondary: toHex(sorted[Math.floor(n * 0.75)]),
            onSurface: toHex(sorted[n - 1]),
            onPrimary: luminance(primary) > 0.3 ? toHex(sorted[0]) : toHex(sorted[n - 1])
        };
    }

    Layout.alignment: Qt.AlignTop | Qt.AlignCenter
    Layout.fillWidth: true
    implicitHeight: contentLoader.implicitHeight
    color: Colours.withAlpha(root.trackArtColors.surfaceVariant, 0.85)
    radius: Appearance.rounding.normal
    visible: Players.active

    function formatTime(seconds) {
        const m = Math.floor((seconds % 3600) / 60);
        const s = Math.floor(seconds % 60);
        const h = Math.floor(seconds / 3600);
        return h > 0 ? `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}` : `${m}:${s.toString().padStart(2, '0')}`;
    }

    property string cachedArtPath: ""

    Process {
        id: artDownloader

        property string targetPath: ""

        function download(url) {
            if (!url || url === "")
                return;
            const hash = Qt.md5(url);
            targetPath = `/tmp/qs_art_${hash}.jpg`;
            command = ["curl", "-sLz", targetPath, "-o", targetPath, url];
            running = true;
        }

        onExited: function (exitCode) {
            if (exitCode === 0)
                root.cachedArtPath = targetPath;
        }
    }

    Connections {
        target: Players.active

        function onTrackArtUrlChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            url.startsWith("http") ? artDownloader.download(url) : root.cachedArtPath = url;
        }
    }

    Component.onCompleted: {
        const url = Players.active?.trackArtUrl ?? "";
        url.startsWith("http") ? artDownloader.download(url) : root.cachedArtPath = url;
    }

    ColorQuantizer {
        id: colorTrackArt

        source: Qt.resolvedUrl(root.cachedArtPath !== "" ? root.cachedArtPath : "root:/Assets/kuru.gif")
        depth: 3
        rescaleSize: 64
    }

    Image {
        anchors.fill: parent
        source: Players.active?.trackArtUrl ?? ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.12
        cache: false
        asynchronous: true
        visible: !!Players.active?.trackArtUrl
    }

    AnimatedImage {
        anchors.fill: parent
        source: "root:/Assets/kuru.gif"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.12
        asynchronous: true
        cache: true
        visible: Players.active === null
    }

    Loader {
        id: contentLoader

        width: parent.width
        active: GlobalStates.isQuickSettingsOpen
        asynchronous: true
        sourceComponent: RowLayout {
            width: contentLoader.width
            spacing: Appearance.spacing.small

            ColumnLayout {
                Layout.margins: 8
                Layout.fillWidth: true
                spacing: 4

                StyledLabel {
                    Layout.fillWidth: true
                    text: Players.active?.trackTitle ?? ""
                    color: root.trackArtColors.onSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: Players.active?.trackArtist ?? ""
                        color: root.trackArtColors.secondary
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: Players.active ? "•" : ""
                        color: root.trackArtColors.muted
                        font.pixelSize: Appearance.fonts.size.small
                    }

                    IconImage {
                        source: Players.active ? Quickshell.iconPath(Players.active.desktopEntry) : ""
                        asynchronous: true
                        implicitWidth: 14
                        implicitHeight: 14
                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(root.url)
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: Players.active == null ? "0:00" : `${root.formatTime(Players.active?.position)} / ${root.formatTime(Players.active?.length)}`
                        color: root.trackArtColors.muted
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.DemiBold

                        Timer {
                            running: GlobalStates.isQuickSettingsOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                            interval: 1000
                            repeat: true
                            onTriggered: Players.active.positionChanged()
                        }
                    }
                }

                Wavy {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    activeColor: root.trackArtColors.primary
                    value: Players.active === null ? 0 : Players.active.length > 0 ? Players.active.position / Players.active.length : 0
                    enableWave: Players.active?.playbackState === MprisPlaybackState.Playing && !pressed
                    onMoved: Players.active ? Players.active.position = value * Players.active.length : {}

                    FrameAnimation {
                        running: GlobalStates.isMediaPlayerOpen && Players.active?.playbackState == MprisPlaybackState.Playing
                        onTriggered: Players.active.positionChanged()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    StyledButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        bgRadius: Appearance.rounding.normal
                        icon.name: Players.active?.shuffle ? "shuffle_on" : "shuffle"
                        icon.color: Players.active?.shuffle ? root.trackArtColors.primary : root.trackArtColors.muted
                        color: "transparent"
                        onClicked: {
                            if (Players.active)
                                Players.active.shuffle = !Players.active.shuffle;
                        }
                    }

                    StyledButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        bgRadius: Appearance.rounding.normal
                        icon.name: "skip_previous"
                        icon.color: root.trackArtColors.onPrimary
                        color: root.trackArtColors.primary
                        onClicked: Players.active?.previous()
                    }

                    Icon {
                        icon: Players.active?.playbackState === MprisPlaybackState.Playing ? "pause_circle" : "play_circle"
                        color: root.trackArtColors.primary
                        font.pixelSize: Appearance.fonts.size.extraLarge * 1.2
                        MArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.active?.togglePlaying()
                        }
                    }

                    StyledButton {
                        implicitWidth: 32
                        implicitHeight: 32
                        icon.name: "skip_next"
                        icon.color: root.trackArtColors.onPrimary
                        bgRadius: Appearance.rounding.normal
                        color: root.trackArtColors.primary
                        onClicked: Players.active?.next()
                    }

                    StyledButton {
                        implicitWidth: 24
                        implicitHeight: 24
                        bgRadius: Appearance.rounding.normal
                        icon.name: Players.active?.loopState === MprisLoopState.Playlist ? "repeat_on" : Players.active?.loopState === MprisLoopState.Track ? "repeat_one_on" : "repeat"
                        icon.color: (Players.active?.loopState === MprisLoopState.Playlist || Players.active?.loopState === MprisLoopState.Track) ? root.trackArtColors.primary : root.trackArtColors.muted
                        color: "transparent"
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
