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

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: Math.max(0, parent.height - GlobalStates.reservedBottomSpace) * root.depthRatio
    edge: Qt.BottomEdge
    edgeOffset: GlobalStates.reservedBottomSpace
    filletRadius: Appearance.rounding.normal
    attachedFilletRadius: root.isPanelMerged ? 0 : Appearance.rounding.normal
    length: root.isPanelActive ? parent.width * root.lengthRatio : root.dockWidth
    open: root.isFocusedMonitor && root.isPanelActive
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

    Loader {
        active: root.isFocusedMonitor && root.isLauncherActive
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Component {

            LauncherModule.Launcher {}
        }
    }

    Loader {
        active: root.isFocusedMonitor && root.isWallpaperActive
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Component {

            WallpaperModule.WallpaperSelector {}
        }
    }
}
