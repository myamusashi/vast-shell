pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.States
import qs.Services

StyledTextInput {
    id: root

    required property var carousel
    required property var controller

    implicitHeight: 40
    placeHolderText: qsTr("Search wallpapers")
    toggleButtonVisible: false

    onTextChanged: {
        WallpaperFileModels.searchQuery = text;
        if (carousel && carousel.count > 0)
            carousel.currentIndex = 0;
    }

    Component.onCompleted: text = WallpaperFileModels.searchQuery

    Keys.onEscapePressed: GlobalStates.isWallpaperSwitcherOpen = false

    onAccepted: selectCurrentWallpaper()

    function selectCurrentWallpaper(): void {
        if (!carousel || carousel.count === 0 || !controller)
            return;
        const list = controller.visibleWallpapers ?? [];
        const selectedPath = list[carousel.currentIndex];
        if (selectedPath === undefined)
            return;
        if (controller.isVideo(selectedPath))
            controller.setVideoWallpaper(selectedPath);
        else
            controller.setWallpaper(selectedPath, selectedPath);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down) {
            carousel.moveCurrentIndex(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            carousel.moveCurrentIndex(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            carousel.moveCurrentIndex(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            carousel.moveCurrentIndex(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            controller.wallpaperType = (controller.wallpaperType + (event.key === Qt.Key_Tab ? 1 : -1) + 2) % 2;
            Qt.callLater(() => carousel.selectCurrentWallpaper());
            event.accepted = true;
        }
    }

}
