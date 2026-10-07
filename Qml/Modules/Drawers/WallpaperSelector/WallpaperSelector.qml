pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base.DrawerComponents
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: parent.height * 0.3
    edge: Qt.BottomEdge
    filletRadius: 40
    length: parent.width * 0.6
    open: GlobalStates.isWallpaperSwitcherOpen
    Component.onCompleted: Wallpaper.requestThumbnailChecks()
    onIsWallpaperSwitcherOpenChanged: {
        if (!isWallpaperSwitcherOpen) {
            GlobalStates.previewWallpaper = "";
            return;
        }
        Wallpaper.wallpaperType = MediaKind.isVideo(Paths.currentWallpaper) ? 1 : 0;
    }

    Image {
        id: colorSourceImage

        asynchronous: true
        visible: false
        Component.onCompleted: {
            Wallpaper.colorSourceImage = colorSourceImage;
        }
    }

    Loader {
        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isWallpaperSwitcherOpen // qmllint disable
        anchors.fill: parent
        asynchronous: true
        sourceComponent: FocusCage {
            active: GlobalStates.isWallpaperSwitcherOpen
            anchors.fill: parent
            anchors.margins: Appearance.spacing.normal
            defaultFocus: content.searchField

            Content {
                id: content

                anchors.fill: parent
                controller: Wallpaper
            }
        }
    }
}
