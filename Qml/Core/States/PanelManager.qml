pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Base
import qs.Core.Configs

Scope {
    id: root

    readonly property var  exclusiveDrawers: ["launcher", "wallpaperSwitcher"]
    readonly property bool isLauncherOpen: activeDrawer === "launcher"
    readonly property bool isWallpaperSwitcherOpen: activeDrawer === "wallpaperSwitcher"
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

    property string        activeDrawer: ""
    property bool          isClipboardOpen: false
    property bool          isDashboardOpen: false
    property bool          isMediaPlayerOpen: false
    property bool          isNotificationCenterOpen: false
    property bool          isQuickSettingsOpen: false
    property bool          isRecordingPanelOpen: false
    property bool          isSessionOpen: false
    property bool          isSettingsOpen: false
    property bool          isWeatherPanelOpen: false
    property real          reservedBottomSpace: 0

    function               closePanel(name) {
        setPanel(name, false);
    }
    function               openPanel(name) {
        setPanel(name, true);
    }
    function               setActiveDrawer(nextDrawer) {
        root.activeDrawer = nextDrawer;
    }
    function               setPanel(name, value) {
        if (root.exclusiveDrawers.includes(name)) {
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

    Behavior on reservedBottomSpace {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }
}
