pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Qcm.Material as MD

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ClippingWrapperRectangle {
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
    property string cachedArtPath: ""

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
        target: Players

        function onIndexChanged() {
            const url = Players.active?.trackArtUrl ?? "";
            url.startsWith("http") ? artDownloader.download(url) : root.cachedArtPath = url;
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

        source: Qt.resolvedUrl(root.cachedArtPath !== "" ? root.cachedArtPath : "root:/Assets/images/kuru.gif")
        depth: 3
        rescaleSize: 64
    }

    HoverHandler {
        id: mouseHandler
    }

    Item {
        anchors.fill: parent

        Image {
            id: trackArt

            anchors.fill: parent
            source: Players.active?.trackArtUrl
            fillMode: Image.PreserveAspectCrop
            opacity: mouseHandler.hovered ? 0.12 : 1
            cache: false
            asynchronous: true
            visible: !!Players.active?.trackArtUrl
            layer.enabled: true
            layer.effect: FastBlur {
                source: trackArt
                radius: 16
            }

            Behavior on opacity {
                NAnim {}
            }
        }

        Loader {
            id: contentLoader

            width: parent.width
            active: GlobalStates.isQuickSettingsOpen
            asynchronous: true
            sourceComponent: ContentMediaPlayer {
                width: contentLoader.width
                trackArtColors: root.trackArtColors
                hovered: mouseHandler.hovered
                formatTime: root.formatTime
            }
        }
    }
}
