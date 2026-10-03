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

    edge: Qt.BottomEdge
    open: GlobalStates.isWallpaperSwitcherOpen
    depth: parent.height * 0.3
    length: parent.width * 0.6
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    Component.onCompleted: Wallpaper.requestThumbnailChecks()

    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen

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
        anchors.fill: parent
        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isWallpaperSwitcherOpen // qmllint disable
        asynchronous: true
        sourceComponent: FocusCage {
            anchors.fill: parent
            anchors.margins: Appearance.spacing.normal

            active: GlobalStates.isWallpaperSwitcherOpen
            defaultFocus: content.searchField

            Content {
                id: content

                anchors.fill: parent
                controller: Wallpaper
            }
        }
    }
}
