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

    property real depthRatio: 0.3
    property bool isWallpaperSwitcherOpen: GlobalStates.isWallpaperSwitcherOpen
    property real lengthRatio: 0.6

    animateDepth: !GlobalStates.isSwitchingDrawer
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    // From the shared ratios while the slot is handing over, so the hand-over
    // morphs from whatever size the previous drawer had, otherwise from this
    // drawer's own ratio, so opening from closed animates from its real size.
    depth: Math.max(0, parent.height - GlobalStates.reservedBottomSpace) * (GlobalStates.isSwitchingDrawer ? GlobalStates.drawerDepthRatio : depthRatio)
    edge: Qt.BottomEdge
    edgeOffset: GlobalStates.reservedBottomSpace
    filletRadius: 40
    length: parent.width * (GlobalStates.isSwitchingDrawer ? GlobalStates.drawerLengthRatio : lengthRatio)
    open: GlobalStates.isWallpaperSwitcherOpen
    Component.onCompleted: Wallpaper.requestThumbnailChecks()
    onIsWallpaperSwitcherOpenChanged: {
        if (!isWallpaperSwitcherOpen) {
            GlobalStates.previewWallpaper = "";
            return;
        }
        GlobalStates.requestDrawerGeometry(lengthRatio, depthRatio);
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
