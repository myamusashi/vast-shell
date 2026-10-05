pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

PathView {
    id: root

    required property var controller
    required property var thumbnailAvailability
    readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)
    required property var visibleWallpapers

    function moveCurrentIndex(step: int): void {
        if (count === 0)
            return;
        currentIndex = (currentIndex + step + count) % count;
    }
    function selectCurrentWallpaper(): void {
        const list = visibleWallpapers ?? [];
        const idx = list.indexOf(Paths.currentWallpaper);
        currentIndex = idx !== -1 ? idx : 0;
    }

    cacheItemCount: Configs.wallpaper.visibleWallpaper + 2
    clip: true
    pathItemCount: Configs.wallpaper.visibleWallpaper
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5

    delegate: Card {
        carouselHeight: root.height
        controller: root.controller
        isCurrent: PathView.isCurrentItem
        thumbnailAvailability: root.thumbnailAvailability
        unitWidth: root.unitWidth

        onActivateRequested: path => {
            if (MediaKind.isVideo(path))
                root.controller.setVideoWallpaper(path);
            else
                root.controller.setWallpaper(path, path);
        }
        onSelectRequested: idx => root.currentIndex = idx
    }
    model: ScriptModel {
        values: root.visibleWallpapers ?? []
    }
    path: Path {
        startX: 0
        startY: root.height / 2

        PathLine {
            x: root.width
            y: root.height / 2
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => selectCurrentWallpaper());
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.isWallpaperSwitcherOpen = false;
            event.accepted = true;
        }
    }
    onCurrentIndexChanged: {
        if (Configs.wallpaper.livePreview && count > 0)
            GlobalStates.previewWallpaper = (visibleWallpapers ?? [])[currentIndex] ?? "";
    }

    Connections {
        function onFilteredWallpaperListChanged(): void {
            root.selectCurrentWallpaper();
        }

        target: WallpaperFileModels
    }
}
