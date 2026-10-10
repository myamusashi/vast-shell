pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

ListView {
    id: root

    required property var  controller
    required property var  thumbnailAvailability
    required property var  visibleWallpapers

    readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)

    function               centerCurrent(animated: bool): void {
        if (currentIndex < 0 || !currentItem || width <= 0)
            return;
        const target   = currentItem.x + currentItem.width / 2 - width / 2;
        const distance = Math.abs(target - contentX);
        if (distance < 0.5)
            return;
        if (!animated || distance > width * 1.2) {
            centerAnimation.stop();
            contentX = target;
            return;
        }
        centerAnimation.from = contentX;
        centerAnimation.to   = target;
        centerAnimation.restart();
    }
    function               indexAtViewportCenter(): int {
        if (count === 0 || width <= 0 || height <= 0)
            return -1;
        return indexAt(contentX + width / 2, height / 2);
    }
    function               moveCurrentIndex(step: int): void {
        if (count === 0)
            return;
        currentIndex = (currentIndex + step + count) % count;
    }
    function               selectCurrentWallpaper(): void {
        const list   = visibleWallpapers ?? [];
        const idx    = list.indexOf(Paths.currentWallpaper);
        currentIndex = idx !== -1 ? idx : 0;
    }

    boundsBehavior: ListView.StopAtBounds
    cacheBuffer: unitWidth * 2
    leftMargin: (width - unitWidth) / 2
    rightMargin: (width - unitWidth) / 2
    clip: true
    delegate: Card {
        id: card

        carouselHeight: root.height
        controller: root.controller
        height: root.height
        isCurrent: index === root.currentIndex
        thumbnailAvailability: root.thumbnailAvailability
        width: root.unitWidth
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
    orientation: ListView.Horizontal
    spacing: Appearance.spacing.small

    NumberAnimation {
        id: centerAnimation

        easing.bezierCurve: Appearance.animations.curves.standard
        easing.type: Easing.BezierSpline
        property: "contentX"
        target: root
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            selectCurrentWallpaper();
            root.centerCurrent(false);
        });
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.isWallpaperSwitcherOpen = false;
            event.accepted                       = true;
        }
    }
    onContentXChanged: {
        if (!dragging)
            return;
        const nearest = indexAtViewportCenter();
        if (nearest !== -1)
            currentIndex = nearest;
    }
    onCurrentIndexChanged: {
        if (!dragging)
            root.centerCurrent(true);
        if (Configs.wallpaper.livePreview && count > 0)
            GlobalStates.previewWallpaper = (visibleWallpapers ?? [])[currentIndex] ?? "";
    }
    onHeightChanged: Qt.callLater(() => root.centerCurrent(false))
    onMovementEnded: {
        const nearest = root.indexAtViewportCenter();
        if (nearest !== -1 && nearest !== currentIndex)
            currentIndex = nearest;
        else
            root.centerCurrent(true);
    }
    onWidthChanged: Qt.callLater(() => root.centerCurrent(false))

    Connections {
        function onFilteredWallpaperListChanged(): void {
            root.selectCurrentWallpaper();
            Qt.callLater(() => root.centerCurrent(false));
        }

        target: WallpaperFileModels
    }
}
