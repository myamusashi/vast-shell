pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    required property ScreenBorder border

    readonly property real         dockWidth: DockServices.contentLength(parent.width)
    readonly property bool         isDockVisible: border.isDockVisible
    readonly property bool         isLauncherActive: GlobalStates.isLauncherOpen
    readonly property bool         isPanelActive: isLauncherActive || isWallpaperActive
    readonly property bool         isPanelAttached: root.isDockVisible && root.isPanelActive && !root.isPanelMerged
    readonly property bool         isPanelMerged: root.dockWidth <= root.activePanelWidth
    readonly property bool         isWallpaperActive: GlobalStates.isWallpaperSwitcherOpen
    readonly property real         launcherDepthRatio: 0.5
    readonly property real         launcherLengthRatio: 0.45
    readonly property real         panelDepthRatio: isLauncherActive ? launcherDepthRatio : wallpaperDepthRatio
    readonly property real         panelLengthRatio: isLauncherActive ? launcherLengthRatio : wallpaperLengthRatio
    readonly property real         panelWidth: parent.width * panelLengthRatio
    readonly property real         reservedHeight: isDockVisible ? Configs.dock.dockHeight : 0
    readonly property real         wallpaperDepthRatio: 0.3
    readonly property real         wallpaperLengthRatio: 0.6

    property real                  activePanelWidth: 0
    property bool                  panelVisible: false
    property var                   parentWindow: null

    function                       consumeLauncherDeepLink(): void {
        const deepLink = GlobalStates.launcherQuery;

        if (deepLink === "")
            return;

        LauncherServices.query     = deepLink;
        GlobalStates.launcherQuery = "";
    }
    function                       syncReservedSpace(): void {
        if (!root.border.isFocusedMonitor)
            return;

        DockServices.setReservedBottomSpace(root.reservedHeight);
    }

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    clipContent: true
    color: GlobalStates.drawerColors
    cornerRadius: root.panelVisible && root.isPanelMerged ? 0 : Appearance.rounding.large
    depth: Configs.dock.dockHeight
    edge: Qt.BottomEdge
    edgeOffset: 0
    filletRadius: Appearance.rounding.normal
    length: root.isPanelActive && !root.isPanelAttached ? root.panelWidth : root.dockWidth
    open: root.isDockVisible
    Behavior on length {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Behavior on cornerRadius {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Component.onCompleted: {
        root.syncReservedSpace();
        Wallpaper.requestThumbnailChecks();
    }
    onReservedHeightChanged: syncReservedSpace()

    Connections {
        function onIsFocusedMonitorChanged() {
            root.syncReservedSpace();
        }

        target: root.border
    }

    Connections {
        function onIsLauncherActiveChanged() {
            if (!root.isLauncherActive)
                return;

            root.activePanelWidth = root.parent.width * root.launcherLengthRatio;

            if (!root.border.isFocusedMonitor)
                return;

            LauncherServices.reset();
            root.consumeLauncherDeepLink();
        }

        target: root
    }

    Connections {
        function onIsLauncherQueryChanged() {
            if (!root.isLauncherActive || !root.border.isFocusedMonitor)
                return;

            root.consumeLauncherDeepLink();
        }

        target: GlobalStates
    }

    Connections {
        function onIsWallpaperActiveChanged() {
            if (!root.isWallpaperActive) {
                if (root.border.isFocusedMonitor)
                    GlobalStates.previewWallpaper = "";
                return;
            }

            root.activePanelWidth = root.parent.width * root.wallpaperLengthRatio;

            if (!root.border.isFocusedMonitor)
                return;

            Wallpaper.wallpaperType = MediaKind.isVideo(Paths.currentWallpaper) ? 1 : 0;
        }

        target: root
    }

    Loader {
        active: root.isDockVisible
        anchors.fill: parent
        asynchronous: true
        sourceComponent: DockRow {
            screen: root.border.window
            parentWindow: root.parentWindow
        }
    }
}
