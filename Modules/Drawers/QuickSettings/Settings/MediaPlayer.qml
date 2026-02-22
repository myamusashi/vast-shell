pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Components

ClippingWrapperRectangle {
    id: root

    property url url: ""
    // thx claude
    property var trackArtColors: {
        const FALLBACK = {
            primary: "#D0BCFF",
            onPrimary: "#381E72",
            primaryContainer: "#4F378B",
            onPrimaryContainer: "#EADDFF",
            secondary: "#CCC2DC",
            onSecondary: "#332D41",
            tertiary: "#EFB8C8",
            onTertiary: "#492532",
            surface: "#141218",
            surfaceVariant: "#49454F",
            onSurface: "#E6E1E5",
            onSurfaceVariant: "#CAC4D0",
            outline: "#938F99"
        };

        if (colorTrackArt.colors.length === 0)
            return FALLBACK;

        function toHex(c) {
            const ch = v => Math.round(v * 255).toString(16).padStart(2, '0');
            return `#${ch(c.r)}${ch(c.g)}${ch(c.b)}`;
        }

        function luminance(c) {
            const lin = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
            return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
        }

        function contrastRatio(l1, l2) {
            const [lighter, darker] = l1 > l2 ? [l1, l2] : [l2, l1];
            return (lighter + 0.05) / (darker + 0.05);
        }

        function hslSaturation(c) {
            const max = Math.max(c.r, c.g, c.b);
            const min = Math.min(c.r, c.g, c.b);
            const lightness = (max + min) / 2;
            return (max === min) ? 0 : (max - min) / (1 - Math.abs(2 * lightness - 1));
        }

        function chroma(c) {
            return hslSaturation(c) * luminance(c);
        }

        function onColor(bgLuminance, lightEntry, darkEntry) {
            const contrastWithLight = contrastRatio(bgLuminance, lightEntry.lum);
            const contrastWithDark = contrastRatio(bgLuminance, darkEntry.lum);
            return toHex(contrastWithLight >= contrastWithDark ? lightEntry.color : darkEntry.color);
        }

        const tones = Array.from(colorTrackArt.colors).map(c => ({
                    color: c,
                    lum: luminance(c)
                })).sort((a, b) => a.lum - b.lum);

        const n = tones.length;
        const black = tones[0];            // tone ~0  – darkest sample
        const white = tones[n - 1];        // tone ~100 – lightest sample

        function atTone(t) {
            return tones[Math.max(0, Math.min(n - 1, Math.round(t * (n - 1))))];
        }

        const surfaceTone = atTone(0.06);
        const surfaceVariantTone = atTone(0.17);
        const outlineTone = atTone(0.60);

        function mostVivid(fromRatio, toRatio) {
            return tones.slice(Math.floor(fromRatio * n), Math.ceil(toRatio * n)).reduce((best, cur) => chroma(cur.color) > chroma(best.color) ? cur : best);
        }

        const primaryTone = mostVivid(0.70, 1.00); // tone ~80
        const primaryContainerTone = mostVivid(0.20, 0.45); // tone ~30

        const secondaryTone = atTone(0.75);
        const tertiaryTone = atTone(0.88);

        return {
            // Surface roles
            surface: toHex(surfaceTone.color),
            surfaceVariant: toHex(surfaceVariantTone.color),
            onSurface: toHex(white.color),
            onSurfaceVariant: toHex(outlineTone.color),
            outline: toHex(outlineTone.color),

            // Primary roles
            primary: toHex(primaryTone.color),
            onPrimary: onColor(primaryTone.lum, white, black),
            primaryContainer: toHex(primaryContainerTone.color),
            onPrimaryContainer: onColor(primaryContainerTone.lum, white, black),

            // Secondary roles
            secondary: toHex(secondaryTone.color),
            onSecondary: onColor(secondaryTone.lum, white, black),

            // Tertiary roles
            tertiary: toHex(tertiaryTone.color),
            onTertiary: onColor(tertiaryTone.lum, white, black)
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
