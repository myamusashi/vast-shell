pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Vast

import qs.Configs
import qs.Helpers
import qs.Services

Singleton {
    id: root

    readonly property alias isVolumeOSDShow: root.isVolumeOSDVisible
    readonly property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    readonly property alias isNumLockOSDShow: root.isNumLockOSDVisible
    readonly property bool isVolumeOSDVisible: _activeOSDs["volume"] || false
    readonly property bool isCapsLockOSDVisible: _activeOSDs["capslock"] || false
    readonly property bool isNumLockOSDVisible: _activeOSDs["numlock"] || false

    readonly property color drawerColors: Configs.generals.transparent ? Qt.alpha(Colours.m3Colors.m3Background, Configs.generals.alpha) : Colours.m3Colors.m3Background
    readonly property int osdDisplayDuration: 5000
    readonly property int cleanupDelay: 500
    readonly property string currentLanguage: TranslationManager.currentLanguage

    readonly property var osdTimers: ({
            "volume": volumeTimer,
            "capslock": capslockTimer,
            "numlock": numlockTimer
        })

    readonly property var panelProps: ({
            "calendar": "isCalendarOpen",
            "screenCapture": "isScreenCapturePanelOpen",
            "launcher": "isLauncherOpen",
            "bar": "isBarOpen",
            "session": "isSessionOpen",
            "mediaPlayer": "isMediaPlayerOpen",
            "notificationCenter": "isNotificationCenterOpen",
            "quickSettings": "isQuickSettingsOpen",
            "wallpaperSwitcher": "isWallpaperSwitcherOpen",
            "overview": "isOverviewOpen",
            "weather": "isWeatherPanelOpen",
            "dashboard": "isDashboardOpen"
        })

    property bool isSettingsOpen: false
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
    property bool isSelectionOpen: false

    property string scriptPath: `${Paths.rootDir}/Assets/shell/screen-capture.sh`

    property var _activeOSDs: ({})
    property var _pausedOSDs: ({})

    function setPanel(name: string, value: bool): void {
        const prop = panelProps[name];
        if (prop)
            root[prop] = value;
        else
            console.warn("Unknown panel:", name);
    }

    function togglePanel(name: string): void {
        const prop = panelProps[name];
        if (prop)
            setPanel(name, !root[prop]);
    }

    function openPanel(name: string): void {
        setPanel(name, true);
    }
    function closePanel(name: string): void {
        setPanel(name, false);
    }

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
        _activeOSDs[osdName] ? hideOSD(osdName) : showOSD(osdName);
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

    component OSDTimer: Timer {
        required property string osdName
        interval: root.osdDisplayDuration
        repeat: false
        onTriggered: root.hideOSD(osdName)
    }

    function _startOSDTimer(osdName: string): void {
        osdTimers[osdName]?.restart();
    }

    function _stopOSDTimer(osdName: string): void {
        osdTimers[osdName]?.stop();
    }

    function _checkAndClosePanelWindow() {
        const anyVisible = Object.keys(_activeOSDs).some(key => _activeOSDs[key] === true);
        if (!anyVisible)
            cleanupTimer.start();
    }

    OSDTimer {
        id: volumeTimer
        osdName: "volume"
    }
    OSDTimer {
        id: capslockTimer
        osdName: "capslock"
    }
    OSDTimer {
        id: numlockTimer
        osdName: "numlock"
    }

    component PanelController: QtObject {
        id: panelController

        required property string panelName
        required property string shortcutName

        property IpcHandler ipc: IpcHandler {
            target: panelController.panelName
            function open(): void {
                GlobalStates.openPanel(panelController.panelName);
            }
            function close(): void {
                GlobalStates.closePanel(panelController.panelName);
            }
            function toggle(): void {
                GlobalStates.togglePanel(panelController.panelName);
            }
        }

        property GlobalShortcut shortcut: GlobalShortcut {
            name: panelController.shortcutName
            onPressed: GlobalStates.togglePanel(panelController.panelName)
        }
    }

    Variants {
        model: [
            {
                panel: "wallpaperSwitcher",
                shortcut: "wallpaperSwitcher"
            },
            {
                panel: "bar",
                shortcut: "layershell"
            },
            {
                panel: "launcher",
                shortcut: "appLauncher"
            },
            {
                panel: "screenCapture",
                shortcut: "screencaptureLauncher"
            },
            {
                panel: "overview",
                shortcut: "overview"
            },
            {
                panel: "quickSettings",
                shortcut: "QuickSettings"
            },
            {
                panel: "session",
                shortcut: "session"
            },
            {
                panel: "weather",
                shortcut: "weather"
            },
            {
                panel: "dashboard",
                shortcut: "dashboard"
            },
        ]
        delegate: PanelController {
            required property var modelData
            panelName: modelData.panel
            shortcutName: modelData.shortcut
        }
    }

    IpcHandler {
        target: "img"

        function set(path: string): void {
            Quickshell.execDetached({
                command: ["sh", "-c", `printf '%s' ${JSON.stringify(path)} > ${JSON.stringify(Paths.currentWallpaperFile)}`]
            });
            Quickshell.execDetached({
                command: ["matugen", "image", path]
            });
        }

        function get(): string {
            return Paths.currentWallpaper;
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
        target: KeylockState
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
}
