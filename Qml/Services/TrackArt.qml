pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.ImageCache
import Vast.Utils
import qs.Core.Configs
import qs.Services

Singleton {
    id: root

    readonly property var fallbackColors: ({
            primary: Colours.m3Colors.m3Primary,
            onPrimary: Colours.m3Colors.m3OnPrimary,
            primaryContainer: Colours.m3Colors.m3PrimaryContainer,
            onPrimaryContainer: Colours.m3Colors.m3OnPrimaryContainer,
            secondary: Colours.m3Colors.m3Secondary,
            onSecondary: Colours.m3Colors.m3OnSecondary,
            tertiary: Colours.m3Colors.m3Tertiary,
            onTertiary: Colours.m3Colors.m3OnTertiary,
            surface: Colours.m3Colors.m3SurfaceContainerHighest,
            surfaceVariant: Colours.m3Colors.m3SurfaceVariant,
            onSurface: Colours.m3Colors.m3OnSurface,
            onSurfaceVariant: Colours.m3Colors.m3OnSurfaceVariant,
            outline: Colours.m3Colors.m3Outline
        })
    property var colors: fallbackColors
    property string cachedPath: ""

    function refresh() {
        const url = String(Players.active?.trackArtUrl ?? "");
        root.cachedPath = "";
        if (url.startsWith("http"))
            downloader.download(url);
        else {
            root.cachedPath = url;
            const localPath = url.replace("file://", "");
            if (localPath)
                ImageCache.copyAndPreload(localPath, Qt.size(300, 300));
        }
    }

    Process {
        id: downloader

        property string targetPath: ""

        function download(url) {
            const hash = Qt.md5(url);
            targetPath = `/tmp/qs_art_${hash}.jpg`;
            exec(["curl", "-sLz", targetPath, "-o", targetPath, url]);
        }
        onExited: function (exitCode, exitStatus) { // qmllint disable
            if (exitStatus === 0 && exitCode === 0 && targetPath === `/tmp/qs_art_${Qt.md5(Players.active?.trackArtUrl ?? "")}.jpg`)
                root.cachedPath = targetPath;
        }
    }

    ColorMaterial {
        source: root.cachedPath
        darkMode: Configs.colors.isDarkMode
        scheme: Colours.schemeEnum(Configs.colors.scheme)
        onColorsChanged: {
            if (ready)
                root.colors = colors;
        }
    }

    Connections {
        target: Players
        function onIndexChanged() {
            root.refresh();
        }
    }

    Connections {
        target: Players.active
        function onTrackChanged() {
            root.refresh();
        }
        function onPostTrackChanged() {
            root.refresh();
        }
        function onTrackArtUrlChanged() {
            root.refresh();
        }
    }

    onCachedPathChanged: root.colors = root.fallbackColors
    Component.onCompleted: root.refresh()
}
