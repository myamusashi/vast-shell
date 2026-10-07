pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Scope {
    id: root

    readonly property var panelProps: ({
            "calendar": "isCalendarOpen",
            "launcher": "isLauncherOpen",
            "session": "isSessionOpen",
            "mediaPlayer": "isMediaPlayerOpen",
            "notificationCenter": "isNotificationCenterOpen",
            "quickSettings": "isQuickSettingsOpen",
            "wallpaperSwitcher": "isWallpaperSwitcherOpen",
            "weather": "isWeatherPanelOpen",
            "settings": "isSettingsOpen",
            "clipboard": "isClipboardOpen",
            "recordingPanel": "isRecordingPanelOpen"
        })

    property bool         isCalendarOpen: false
    property bool         isClipboardOpen: false
    property bool         isLauncherOpen: false
    property bool         isMediaPlayerOpen: false
    property bool         isNotificationCenterOpen: false
    property bool         isQuickSettingsOpen: false
    property bool         isRecordingPanelOpen: false
    property bool         isSessionOpen: false
    property bool         isSettingsOpen: false
    property bool         isWallpaperSwitcherOpen: false
    property bool         isWeatherPanelOpen: false

    function              closePanel(name) {
        setPanel(name, false);
    }
    function              openPanel(name) {
        setPanel(name, true);
    }
    function              setPanel(name, value) {
        const prop = panelProps[name];
        if (prop)
            root[prop] = value;
        else
            console.warn("Unknown panel:", name);
    }
    function              togglePanel(name) {
        const prop = panelProps[name];
        if (prop)
            setPanel(name, !root[prop]);
    }
}
