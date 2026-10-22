pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    required property var  controller
    required property var  thumbnailAvailability
    required property var  visibleWallpapers

    readonly property int  baseIndex: Math.max(0, Math.min(count - 1, Math.floor(position)))
    readonly property int  count: (visibleWallpapers ?? []).length
    readonly property real focusX: {
        const firstCenter  = leftEdgeOf(baseIndex) + widthOf(baseIndex) / 2;
        const secondCenter = leftEdgeOf(baseIndex + 1) + widthOf(baseIndex + 1) / 2;
        return firstCenter + (secondCenter - firstCenter) * fraction;
    }
    readonly property real fraction: position - baseIndex
    readonly property real largeWidth: unitWidth * 1.2
    readonly property real smallWidth: unitWidth * 0.72
    readonly property real unitWidth: width / (Configs.wallpaper.visibleWallpaper + 1)

    property bool          applyOnClick: false
    property bool          closeDrawerOnEscape: true
    property int           currentIndex: 0
    property real          position: 0

    function               animateToCurrent(): void {
        positionAnimation.stop();
        positionAnimation.from = position;
        positionAnimation.to   = clampPosition(currentIndex);
        positionAnimation.restart();
    }
    function               applyWallpaper(path: string): void {
        if (path === "")
            return;
        if (MediaKind.isVideo(path))
            controller.setVideoWallpaper(path);
        else
            controller.setWallpaper(path, path);
    }
    function               clampPosition(value: real): real {
        return Math.max(0, Math.min(count - 1, value));
    }
    function               closenessOf(itemIndex: int): real {
        return Math.max(0, 1 - Math.abs(itemIndex - position));
    }
    function               jumpToCurrent(): void {
        positionAnimation.stop();
        position = clampPosition(currentIndex);
    }
    function               leftEdgeOf(itemIndex: int): real {
        let growth = 0;
        if (itemIndex > baseIndex)
            growth += 1 - fraction;
        if (itemIndex > baseIndex + 1)
            growth += fraction;
        return itemIndex * (smallWidth + Appearance.spacing.small) + (largeWidth - smallWidth) * growth;
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
        jumpToCurrent();
    }
    function               widthOf(itemIndex: int): real {
        return smallWidth + (largeWidth - smallWidth) * closenessOf(itemIndex);
    }

    clip: true

    Repeater {
        model: ScriptModel {
            values: root.visibleWallpapers ?? []
        }
        delegate: Card {
            id: card

            closeness: root.closenessOf(index)
            controller: root.controller
            height: root.height
            isCurrent: index === root.currentIndex
            thumbnailAvailability: root.thumbnailAvailability
            viewportWidth: root.width
            visible: x + width > -root.unitWidth && x < root.width + root.unitWidth
            width: root.widthOf(index)
            x: root.width / 2 + root.leftEdgeOf(index) - root.focusX
            onActivateRequested: path => root.applyWallpaper(path)
            onSelectRequested: idx => {
                root.currentIndex = idx;
                if (root.applyOnClick)
                    root.applyWallpaper((root.visibleWallpapers ?? [])[idx] ?? "");
            }
        }
    }

    NAnim {
        id: positionAnimation

        duration: Appearance.animations.durations.expressiveDefaultSpatial
        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        property: "position"
        target: root
    }

    DragHandler {
        id: dragHandler

        property real startPosition: 0

        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        onActiveChanged: {
            if (active) {
                positionAnimation.stop();
                startPosition = root.position;
                return;
            }
            root.animateToCurrent();
        }
        onTranslationChanged: {
            if (!active)
                return;
            root.position = root.clampPosition(startPosition - translation.x / (root.smallWidth + Appearance.spacing.small));
            const nearest = Math.round(root.position);
            if (nearest !== root.currentIndex)
                root.currentIndex = nearest;
        }
    }

    Component.onCompleted: {
        Qt.callLater(() => root.selectCurrentWallpaper());
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && root.closeDrawerOnEscape) {
            GlobalStates.closePanel("wallpaperSwitcher");
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.currentIndex = Math.max(0, root.currentIndex - 1);
            event.accepted    = true;
        } else if (event.key === Qt.Key_Right) {
            root.currentIndex = Math.min(root.count - 1, root.currentIndex + 1);
            event.accepted    = true;
        }
    }
    onCurrentIndexChanged: {
        if (!dragHandler.active)
            root.animateToCurrent();
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
