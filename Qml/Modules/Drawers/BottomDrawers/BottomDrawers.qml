pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "Dock" as DockModule
import "Launcher" as LauncherModule
import "WallpaperSelector" as WallpaperModule

Item {
    id: root

    required property ScreenBorder border

    readonly property real         availableHeight: Math.max(0, parent.height - reservedHeight)
    readonly property real         baseDockLength: DockServices.contentLength(parent.width)
    readonly property real         cornerRadius: Appearance.rounding.normal
    readonly property real         filletRadius: Appearance.rounding.normal
    readonly property int          halfDuration: Math.round(totalDuration / 2)
    readonly property bool         isDockMergedToPanel: isDockVisible && baseDockLength <= targetPanelLength
    readonly property bool         isDockVisible: border.isDockVisible
    readonly property bool         isFocusedMonitor: border.isFocusedMonitor
    readonly property bool         isLauncherActive: GlobalStates.activeDrawer === "launcher"
    readonly property bool         isLauncherPanel: isLauncherActive || (!isPanelActive && lastPanel === "launcher")
    readonly property bool         isPanelActive: GlobalStates.activeDrawer !== ""
    readonly property bool         isTransitioning: openMergedTransition.running || openDirectTransition.running || closeMergedTransition.running || closeDirectTransition.running || switchTransition.running
    readonly property bool         isWallpaperActive: GlobalStates.activeDrawer === "wallpaperSwitcher"
    readonly property real         launcherDepth: Math.round(availableHeight * 0.5)
    readonly property real         launcherLength: Math.round(parent.width * 0.45)
    readonly property list<Item>   maskItems: [dockMask, panelMask]
    readonly property real         parentBottomInset: parent?.bottomInset ?? 0 // qmllint disable missing-property
    readonly property real         parentHoleWidth: parent?.holeWidth ?? (parent ? parent.width : 0) // qmllint disable missing-property
    readonly property real         parentLeftInset: parent?.leftInset ?? 0 // qmllint disable missing-property
    readonly property real         reservedHeight: isDockVisible ? Configs.dock.dockHeight : 0
    readonly property bool         shouldOpenPanel: isFocusedMonitor && isPanelActive
    readonly property real         snappedDockDepth: Math.round(animatedDockDepth)
    readonly property real         snappedDockLength: Math.round(animatedDockLength)
    readonly property real         snappedMaxLength: Math.max(snappedDockLength, snappedPanelLength)
    readonly property real         snappedPanelDepth: Math.round(animatedPanelDepth)
    readonly property real         snappedPanelLength: Math.round(animatedPanelLength)
    readonly property real         snappedTotalDepth: snappedDockDepth + snappedPanelDepth
    readonly property real         stepFilletRadius: Appearance.rounding.normal
    readonly property real         targetPanelDepth: isLauncherPanel ? launcherDepth : wallpaperDepth
    readonly property real         targetPanelLength: isLauncherPanel ? launcherLength : wallpaperLength
    readonly property int          totalDuration: Appearance.animations.durations.expressiveDefaultSpatial
    readonly property real         wallpaperDepth: Math.round(availableHeight * 0.3)
    readonly property real         wallpaperLength: Math.round(parent.width * 0.6)

    property real                  animatedDockDepth: isDockVisible ? Configs.dock.dockHeight : 0
    property real                  animatedDockLength: baseDockLength
    property real                  animatedPanelDepth: 0
    property real                  animatedPanelLength: targetPanelLength
    property string                lastPanel: "launcher"
    property var                   parentWindow: null

    function                       centeredScreenX(itemWidth: real): real {
        return Math.round(parentLeftInset + (parentHoleWidth - itemWidth) / 2);
    }

    function                       consumeLauncherDeepLink(): void {
        const deepLink = GlobalStates.launcherQuery;

        if (deepLink === "")
            return;

        LauncherServices.query     = deepLink;
        GlobalStates.launcherQuery = "";
    }

    function                       dockLengthFor(panelWidth: real): real {
        return (isDockVisible && baseDockLength <= panelWidth) ? panelWidth : baseDockLength;
    }

    function                       syncReservedSpace(): void {
        if (!root.isFocusedMonitor)
            return;

        DockServices.setReservedBottomSpace(root.reservedHeight);
    }

    height: snappedTotalDepth
    state: !shouldOpenPanel ? "closed" : (isLauncherPanel ? "launcher" : "wallpaper")
    visible: snappedTotalDepth > 0
    width: snappedMaxLength + filletRadius * 2
    x: centeredScreenX(width)
    y: Math.round(parent.height - parentBottomInset - height)
    states: [
        State {
            name: "closed"

            PropertyChanges {
                root.animatedDockLength: root.baseDockLength
                root.animatedPanelDepth: 0
                root.animatedPanelLength: root.targetPanelLength
            }
        },
        State {
            name: "launcher"

            PropertyChanges {
                root.animatedDockLength: root.dockLengthFor(root.launcherLength)
                root.animatedPanelDepth: root.launcherDepth
                root.animatedPanelLength: root.launcherLength
            }
        },
        State {
            name: "wallpaper"

            PropertyChanges {
                root.animatedDockLength: root.dockLengthFor(root.wallpaperLength)
                root.animatedPanelDepth: root.wallpaperDepth
                root.animatedPanelLength: root.wallpaperLength
            }
        }
    ]
    transitions: [
        Transition {
            id: openMergedTransition

            enabled: root.isDockMergedToPanel
            from: "closed"
            to: "launcher,wallpaper"

            SequentialAnimation {

                PropertyAction {
                    property: "animatedPanelLength"
                    target: root
                }

                SpatialAnim {
                    duration: root.halfDuration
                    property: "animatedDockLength"
                    target: root
                }

                SpatialAnim {
                    duration: root.halfDuration
                    property: "animatedPanelDepth"
                    target: root
                }
            }
        },
        Transition {
            id: openDirectTransition

            enabled: !root.isDockMergedToPanel
            from: "closed"
            to: "launcher,wallpaper"

            ParallelAnimation {

                PropertyAction {
                    property: "animatedPanelLength"
                    target: root
                }

                SpatialAnim {
                    properties: "animatedDockLength,animatedPanelDepth"
                    target: root
                }
            }
        },
        Transition {
            id: closeMergedTransition

            enabled: root.isDockMergedToPanel
            from: "launcher,wallpaper"
            to: "closed"

            SequentialAnimation {

                SpatialAnim {
                    duration: root.halfDuration
                    property: "animatedPanelDepth"
                    target: root
                }

                SpatialAnim {
                    duration: root.halfDuration
                    property: "animatedDockLength"
                    target: root
                }
            }
        },
        Transition {
            id: closeDirectTransition

            enabled: !root.isDockMergedToPanel
            from: "launcher,wallpaper"
            to: "closed"

            SpatialAnim {
                properties: "animatedDockLength,animatedPanelDepth"
                target: root
            }
        },
        Transition {
            id: switchTransition

            from: "launcher,wallpaper"
            to: "launcher,wallpaper"

            SpatialAnim {
                properties: "animatedDockLength,animatedPanelLength,animatedPanelDepth"
                target: root
            }
        }
    ]
    Behavior on animatedDockDepth {
        SpatialAnim {}
    }
    Behavior on animatedDockLength {
        enabled: !root.isTransitioning

        SpatialAnim {}
    }
    Component.onCompleted: {
        root.syncReservedSpace();
        Wallpaper.requestThumbnailChecks();
    }
    onIsFocusedMonitorChanged: syncReservedSpace()
    onIsLauncherActiveChanged: {
        if (!isLauncherActive)
            return;

        lastPanel = "launcher";

        if (!isFocusedMonitor)
            return;

        LauncherServices.reset();
        consumeLauncherDeepLink();
    }
    onIsWallpaperActiveChanged: {
        if (!isWallpaperActive) {
            if (isFocusedMonitor)
                GlobalStates.previewWallpaper = "";
            return;
        }

        lastPanel = "wallpaper";

        if (!isFocusedMonitor)
            return;

        Wallpaper.wallpaperType = MediaKind.isVideo(Paths.currentWallpaper) ? 1 : 0;
    }
    onReservedHeightChanged: syncReservedSpace()

    Connections {

        function onIsLauncherQueryChanged() {
            if (!root.isLauncherActive || !root.isFocusedMonitor)
                return;

            root.consumeLauncherDeepLink();
        }

        target: GlobalStates
    }

    BottomDrawerShape {
        borderOverlap: 1
        color: GlobalStates.drawerColors
        cornerRadius: root.cornerRadius
        dockDepth: root.snappedDockDepth
        dockLength: root.snappedDockLength
        filletRadius: root.filletRadius
        panelDepth: root.snappedPanelDepth
        panelLength: root.snappedPanelLength
        stepFilletRadius: root.stepFilletRadius
    }

    Item {
        id: dockMask

        height: root.snappedDockDepth
        visible: root.snappedDockDepth > 0
        width: root.snappedDockLength + root.filletRadius * 2
        x: Math.round((root.width - width) / 2)
        y: root.height - height
    }

    Item {
        id: panelMask

        readonly property real filletPadding: root.snappedDockDepth <= 0 ? root.filletRadius * 2 : Math.max(0, Math.min(root.stepFilletRadius * 2, root.snappedDockLength - root.snappedPanelLength))

        height: root.snappedPanelDepth
        visible: root.snappedPanelDepth > 0
        width: root.snappedPanelLength + filletPadding
        x: Math.round((root.width - width) / 2)
        y: root.height - root.snappedDockDepth - height
    }

    Loader {
        active: root.isFocusedMonitor
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Item {
            anchors.fill: parent

            Item {
                clip: true
                enabled: root.isDockVisible
                height: root.snappedDockDepth
                visible: root.snappedDockDepth > 0
                width: root.snappedDockLength
                x: Math.round((root.width - width) / 2)
                y: root.height - height

                DockModule.DockRow {
                    parentWindow: root.parentWindow
                    screen: root.border.window
                }
            }

            Item {
                id: panelClip

                clip: true
                height: root.snappedPanelDepth
                visible: root.snappedPanelDepth > 0
                width: root.snappedPanelLength
                x: Math.round((root.width - width) / 2)
                y: root.height - root.snappedDockDepth - height

                Item {
                    enabled: root.isLauncherActive
                    height: root.launcherDepth
                    visible: root.isLauncherActive
                    width: root.launcherLength
                    x: root.centeredScreenX(width) - root.x - panelClip.x
                    y: 0

                    LauncherModule.Launcher {}
                }

                Item {
                    enabled: root.isWallpaperActive
                    height: root.wallpaperDepth
                    visible: root.isWallpaperActive
                    width: root.wallpaperLength
                    x: root.centeredScreenX(width) - root.x - panelClip.x
                    y: 0

                    WallpaperModule.WallpaperSelector {}
                }
            }
        }
    }

    component SpatialAnim: NAnim {
        duration: root.totalDuration
        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
    }
}
