pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Base
import qs.Core.Configs

Scope {
    id: root

    // Drawers sharing one slot: at most one can be active, and the geometry below
    // is the only source of their size, so a hand-over resizes one drawer shape.
    readonly property var  exclusiveDrawers: ["launcher", "wallpaperSwitcher"]
    readonly property bool isLauncherOpen: activeDrawer === "launcher"
    readonly property bool isWallpaperSwitcherOpen: activeDrawer === "wallpaperSwitcher"
    readonly property real launcherLengthRatio: 0.45
    readonly property var  panelProps: ({
            "dashboard": "isDashboardOpen",
            "session": "isSessionOpen",
            "mediaPlayer": "isMediaPlayerOpen",
            "notificationCenter": "isNotificationCenterOpen",
            "quickSettings": "isQuickSettingsOpen",
            "weather": "isWeatherPanelOpen",
            "settings": "isSettingsOpen",
            "clipboard": "isClipboardOpen",
            "recordingPanel": "isRecordingPanelOpen"
        })
    readonly property real wallpaperSwitcherLengthRatio: 0.6

    property string        activeDrawer: ""
    property real          drawerDepthRatio: 0.5
    property real          drawerLengthRatio: 0.45
    property bool          isClipboardOpen: false
    property bool          isDashboardOpen: false
    property bool          isMediaPlayerOpen: false
    property bool          isNotificationCenterOpen: false
    property bool          isQuickSettingsOpen: false
    property bool          isRecordingPanelOpen: false
    property bool          isSessionOpen: false
    property bool          isSettingsOpen: false
    property bool          isSwitchingDrawer: false
    property bool          isWeatherPanelOpen: false
    property string        pendingDrawer: ""
    property real          reservedBottomSpace: 0

    function               closePanel(name) {
        setPanel(name, false);
    }
    function               openPanel(name) {
        setPanel(name, true);
    }
    function               requestDrawerGeometry(lengthRatio, depthRatio) {
        root.drawerLengthRatio = lengthRatio;
        root.drawerDepthRatio  = depthRatio;
    }
    function               setActiveDrawer(nextDrawer) {
        if (nextDrawer === root.pendingDrawer)
            return;
        root.pendingDrawer = nextDrawer;
        if (nextDrawer === "" || root.activeDrawer === "") {
            root.activeDrawer      = nextDrawer;
            root.isSwitchingDrawer = false;
            switchTimer.stop();
            return;
        }
        // Handing the slot to the other drawer: it appears at the size the
        // outgoing drawer had, and the ratios below carry that size to the new
        // one while the outgoing drawer is already gone in the same frame.
        root.isSwitchingDrawer = true;
        Qt.callLater(() => {
            if (root.pendingDrawer !== nextDrawer)
                return;
            root.activeDrawer = nextDrawer;
            switchTimer.restart();
        });
    }
    function               setPanel(name, value) {
        if (root.exclusiveDrawers.includes(name)) {
            // Closing a drawer that is not the active one must leave the slot alone.
            if (!value && root.activeDrawer !== name)
                return;
            setActiveDrawer(value ? name : "");
            return;
        }
        const prop = panelProps[name];
        if (prop)
            root[prop] = value;
        else
            console.warn("Unknown panel:", name);
    }
    function               togglePanel(name) {
        if (root.exclusiveDrawers.includes(name)) {
            setPanel(name, root.activeDrawer !== name);
            return;
        }
        const prop = panelProps[name];
        if (prop)
            setPanel(name, !root[prop]);
    }

    Behavior on drawerDepthRatio {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Behavior on drawerLengthRatio {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
    Behavior on reservedBottomSpace {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Timer {
        id: switchTimer

        interval: Appearance.animations.durations.expressiveDefaultSpatial
        onTriggered: root.isSwitchingDrawer = false
        repeat: false
    }
}
