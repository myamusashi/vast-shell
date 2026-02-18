pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import TranslationManager

import qs.Configs
import qs.Helpers
import qs.Services

Singleton {
    id: root

    readonly property alias isVolumeOSDShow: root.isVolumeOSDVisible
    readonly property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    readonly property alias isNumLockOSDShow: root.isNumLockOSDVisible
    readonly property int osdDisplayDuration: 5000
    readonly property int cleanupDelay: 500
    readonly property bool isVolumeOSDVisible: _activeOSDs["volume"] || false
    readonly property bool isCapsLockOSDVisible: _activeOSDs["capslock"] || false
    readonly property bool isNumLockOSDVisible: _activeOSDs["numlock"] || false
    readonly property color drawerColors: Configs.generals.transparent ? Colours.withAlpha(Colours.m3Colors.m3Background, Configs.generals.alpha) : Colours.m3Colors.m3Background
    readonly property ShellScreen focusedMonitor: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name)
    readonly property string currentLanguage: TranslationManager.currentLanguage

    property bool isCalendarOpen: false
    property bool isScreenCapturePanelOpen: false
    property bool isLauncherOpen: false
    property bool isBarOpen: Configs.bar.alwaysOpenBar
    property bool isSessionOpen: false
    property bool isMediaPlayerOpen: false
    property bool isNotificationCenterOpen: false
    property bool isQuickSettingsOpen: false
    property bool isWallpaperSwitcherOpen: false
    property bool isOverviewOpen: false
    property bool isDashboardOpen: false
    property bool isWeatherPanelOpen: false
    property bool isLockscreenOpen: false
    property string scriptPath: `${Paths.rootDir}/Assets/screen-capture.sh`
    property var _activeOSDs: ({})
    property var _osdTimerRefs: ({})
    property var _pausedOSDs: ({})

    function showOSD(osdName) {
        if (!osdName)
            return;

        _activeOSDs[osdName] = true;
        _activeOSDsChanged();

        if (!_pausedOSDs[osdName])
            _startOSDTimer(osdName);
    }

    function hideOSD(osdName) {
        if (!osdName)
            return;

        _activeOSDs[osdName] = false;
        _pausedOSDs[osdName] = false;
        _activeOSDsChanged();
        _stopOSDTimer(osdName);
        _checkAndClosePanelWindow();
    }

    function toggleOSD(osdName) {
        if (_activeOSDs[osdName])
            hideOSD(osdName);
        else
            showOSD(osdName);
    }

    function isOSDVisible(osdName) {
        return _activeOSDs[osdName] || false;
    }

    function pauseOSD(osdName) {
        if (!osdName || !_activeOSDs[osdName])
            return;

        _pausedOSDs[osdName] = true;
        _stopOSDTimer(osdName);
    }

    function resumeOSD(osdName) {
        if (!osdName || !_activeOSDs[osdName])
            return;

        _pausedOSDs[osdName] = false;
        _startOSDTimer(osdName);
    }

    function togglePanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = !isCalendarOpen;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = !isScreenCapturePanelOpen;
            break;
        case "launcher":
            isLauncherOpen = !isLauncherOpen;
            break;
        case "bar":
            isBarOpen = !isBarOpen;
            break;
        case "session":
            isSessionOpen = !isSessionOpen;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = !isMediaPlayerOpen;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = !isNotificationCenterOpen;
            break;
        case "quickSettings":
            isQuickSettingsOpen = !isQuickSettingsOpen;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = !isWallpaperSwitcherOpen;
            break;
        case "overview":
            isOverviewOpen = !isOverviewOpen;
            break;
        case "weather":
            isWeatherPanelOpen = !isWeatherPanelOpen;
            break;
        case "dashboard":
            isDashboardOpen = !isDashboardOpen;
            break;
        }
    }

    function openPanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = true;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = true;
            break;
        case "launcher":
            isLauncherOpen = true;
            break;
        case "bar":
            isBarOpen = true;
            break;
        case "session":
            isSessionOpen = true;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = true;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = true;
            break;
        case "quickSettings":
            isQuickSettingsOpen = true;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = true;
            break;
        case "overview":
            isOverviewOpen = true;
            break;
        case "weather":
            isWeatherPanelOpen = true;
            break;
        case "dashboard":
            isDashboardOpen = true;
            break;
        }
    }

    function closePanel(panelName) {
        switch (panelName) {
        case "calendar":
            isCalendarOpen = false;
            break;
        case "screenCapture":
            isScreenCapturePanelOpen = false;
            break;
        case "launcher":
            isLauncherOpen = false;
            break;
        case "bar":
            isBarOpen = false;
            break;
        case "session":
            isSessionOpen = false;
            break;
        case "mediaPlayer":
            isMediaPlayerOpen = false;
            break;
        case "notificationCenter":
            isNotificationCenterOpen = false;
            break;
        case "quickSettings":
            isQuickSettingsOpen = false;
            break;
        case "wallpaperSwitcher":
            isWallpaperSwitcherOpen = false;
            break;
        case "overview":
            isOverviewOpen = false;
            break;
        case "weather":
            isWeatherPanelOpen = false;
            break;
        case "dashboard":
            isDashboardOpen = false;
            break;
        }
    }

    function _startOSDTimer(osdName) {
        _stopOSDTimer(osdName);

        try {
            var timer = timerComponent.createObject(root, {
                "osdName": osdName,
                "interval": osdDisplayDuration
            });

            // qmllint disable
            if (timer) {
                _osdTimerRefs[osdName] = timer;
                timer.start();
                // qmllint enable
            } else {
                console.error("Failed to create OSD timer for:", osdName);
            }
        } catch (e) {
            console.error("Error creating OSD timer:", e);
        }
    }

    function _stopOSDTimer(osdName) {
        if (_osdTimerRefs[osdName]) {
            try {
                _osdTimerRefs[osdName].stop();
                _osdTimerRefs[osdName].destroy();
            } catch (e) {
                console.error("Error stopping OSD timer:", e);
            } finally {
                _osdTimerRefs[osdName] = null;
                delete _osdTimerRefs[osdName];
            }
        }
    }

    function _checkAndClosePanelWindow() {
        var anyVisible = Object.keys(_activeOSDs).some(function (key) {
            return _activeOSDs[key] === true;
        });

        if (!anyVisible)
            cleanupTimer.start();
    }

    IpcHandler {
        target: "wallpaperSwitcher"

        function open(): void {
            GlobalStates.isWallpaperSwitcherOpen = true;
        }
        function close(): void {
            GlobalStates.isWallpaperSwitcherOpen = false;
        }
        function toggle(): void {
            GlobalStates.isWallpaperSwitcherOpen = !GlobalStates.isWallpaperSwitcherOpen;
        }
    }

    GlobalShortcut {
        name: "wallpaperSwitcher"
        onPressed: GlobalStates.isWallpaperSwitcherOpen = !GlobalStates.isWallpaperSwitcherOpen
    }

    IpcHandler {
        target: "layershell"

        function open(): void {
            GlobalStates.isBarOpen = true;
        }
        function close(): void {
            GlobalStates.isBarOpen = false;
        }
        function toggle(): void {
            GlobalStates.isBarOpen = !GlobalStates.isBarOpen;
        }
    }

    GlobalShortcut {
        name: "layershell"
        onPressed: GlobalStates.isBarOpen = !GlobalStates.isBarOpen
    }

    GlobalShortcut {
        name: "appLauncher"
        onPressed: GlobalStates.isLauncherOpen = !GlobalStates.isLauncherOpen
    }

    IpcHandler {
        target: "appLauncher"

        function open(): void {
            GlobalStates.isLauncherOpen = true;
        }
        function close(): void {
            GlobalStates.isLauncherOpen = false;
        }
        function toggle(): void {
            GlobalStates.isLauncherOpen = !GlobalStates.isLauncherOpen;
        }
    }

    IpcHandler {
        target: "screenCaptureLauncher"

        function open(): void {
            GlobalStates.isScreenCapturePanelOpen = true;
        }
        function close(): void {
            GlobalStates.isScreenCapturePanelOpen = false;
        }
        function toggle(): void {
            GlobalStates.isScreenCapturePanelOpen = !GlobalStates.isScreenCapturePanelOpen;
        }
    }

    GlobalShortcut {
        name: "screencaptureLauncher"
        onPressed: GlobalStates.isScreenCapturePanelOpen = !GlobalStates.isScreenCapturePanelOpen
    }

    IpcHandler {
        target: "overview"

        function open(): void {
            GlobalStates.isOverviewOpen = true;
        }
        function close(): void {
            GlobalStates.isOverviewOpen = false;
        }
        function toggle(): void {
            GlobalStates.isOverviewOpen = !GlobalStates.isOverviewOpen;
        }
    }

    GlobalShortcut {
        name: "overview"
        onPressed: GlobalStates.isOverviewOpen = !GlobalStates.isOverviewOpen
    }

    IpcHandler {
        target: "QuickSettings"

        function open(): void {
            GlobalStates.isQuickSettingsOpen = true;
        }
        function close(): void {
            GlobalStates.isQuickSettingsOpen = false;
        }
        function toggle(): void {
            GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
        }
    }

    GlobalShortcut {
        name: "QuickSettings"
        onPressed: GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen
    }

    IpcHandler {
        target: "Session"

        function open(): void {
            GlobalStates.isSessionOpen = true;
        }
        function close(): void {
            GlobalStates.isSessionOpen = false;
        }
        function toggle(): void {
            GlobalStates.isSessionOpen = !GlobalStates.isSessionOpen;
        }
    }

    GlobalShortcut {
        name: "session"
        onPressed: GlobalStates.isSessionOpen = !GlobalStates.isSessionOpen
    }

    IpcHandler {
        target: "weather"

        function open() {
            GlobalStates.openPanel("weather");
        }

        function close() {
            GlobalStates.closePanel("weather");
        }

        function toggle() {
            GlobalStates.togglePanel("weather");
        }
    }

    GlobalShortcut {
        name: "weather"
        onPressed: GlobalStates.togglePanel("weather")
    }

    IpcHandler {
        target: "dashboard"

        function open(): void {
            GlobalStates.isDashboardOpen = true;
        }
        function close(): void {
            GlobalStates.isDashboardOpen = false;
        }
        function toggle(): void {
            GlobalStates.isDashboardOpen = !GlobalStates.isDashboardOpen;
        }
    }

    GlobalShortcut {
        name: "dashboard"
        onPressed: GlobalStates.isDashboardOpen = !GlobalStates.isDashboardOpen
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lock.locked = true;
            GlobalStates.isLockscreenOpen = true;
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }

    IpcHandler {
        target: "img"

        function set(path: string): void {
            Quickshell.execDetached({
                "command": ["sh", "-c", "echo " + path + " >" + Paths.currentWallpaperFile + " && " + `matugen image ${path}`]
            });
        }
        function get(): string {
            return Paths.currentWallpaper;
        }
    }

    Component {
        id: timerComponent

        Timer {
            property string osdName: ""

            interval: root.osdDisplayDuration
            repeat: false
            running: false

            onTriggered: root.hideOSD(osdName)

            Component.onDestruction: {
                if (running)
                    stop();
            }
        }
    }

    Timer {
        id: cleanupTimer

        interval: root.cleanupDelay
        repeat: false
        onTriggered: gc()
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: KeyLockState.state

        function onCapsLockChanged() {
            root.showOSD("capslock");
        }

        function onNumLockChanged() {
            root.showOSD("numlock");
        }
    }

    Connections {
        target: Pipewire.defaultAudioSink.audio

        function onVolumeChanged() {
            root.showOSD("volume");
        }
    }

    Component.onDestruction: {
        for (var key in _osdTimerRefs) {
            if (_osdTimerRefs.hasOwnProperty(key))
                _stopOSDTimer(key);
        }
    }
}
