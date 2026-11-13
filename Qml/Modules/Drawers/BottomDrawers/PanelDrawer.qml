pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States

import "Launcher" as LauncherModule
import "WallpaperSelector" as WallpaperModule

Drawer {
    id: root

    required property ScreenBorder border
    required property real         depthRatio
    required property real         dockWidth
    required property bool         isPanelMerged
    required property real         lengthRatio

    readonly property bool         isFocusedMonitor: border.isFocusedMonitor
    readonly property bool         isLauncherActive: GlobalStates.isLauncherOpen
    readonly property bool         isPanelActive: isLauncherActive || isWallpaperActive
    readonly property bool         isWallpaperActive: GlobalStates.isWallpaperSwitcherOpen
    readonly property bool         launcherShouldBeActive: isFocusedMonitor && isLauncherActive
    readonly property bool         wallpaperShouldBeActive: isFocusedMonitor && isWallpaperActive

    property bool                  launcherKeepAlive: false
    property bool                  wallpaperKeepAlive: false

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: Math.max(0, parent.height - GlobalStates.reservedBottomSpace) * depthRatio
    edge: Qt.BottomEdge
    edgeOffset: GlobalStates.reservedBottomSpace
    filletRadius: Appearance.rounding.normal
    attachedFilletRadius: isPanelMerged ? 0 : Appearance.rounding.normal
    length: isPanelActive ? parent.width * lengthRatio : dockWidth
    open: isFocusedMonitor && isPanelActive
    visible: isFocusedMonitor
    Behavior on attachedFilletRadius {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Behavior on length {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    onLauncherShouldBeActiveChanged: {
        if (launcherShouldBeActive)
            launcherKeepAlive = true;
    }
    onWallpaperShouldBeActiveChanged: {
        if (wallpaperShouldBeActive)
            wallpaperKeepAlive = true;
    }

    Timer {
        id: launcherUnloadTimer

        interval: 120000
        running: root.launcherKeepAlive && !root.launcherShouldBeActive
        onTriggered: root.launcherKeepAlive = false
    }

    Timer {
        id: wallpaperUnloadTimer

        interval: 120000
        running: root.wallpaperKeepAlive && !root.wallpaperShouldBeActive
        onTriggered: root.wallpaperKeepAlive = false
    }

    Loader {
        active: root.launcherShouldBeActive || root.launcherKeepAlive
        anchors.fill: parent
        asynchronous: true
        enabled: root.isLauncherActive
        visible: root.isLauncherActive
        sourceComponent: Component {

            LauncherModule.Launcher {}
        }
    }

    Loader {
        active: root.wallpaperShouldBeActive || root.wallpaperKeepAlive
        anchors.fill: parent
        asynchronous: true
        enabled: root.isWallpaperActive
        visible: root.isWallpaperActive
        sourceComponent: Component {

            WallpaperModule.WallpaperSelector {}
        }
    }
}
