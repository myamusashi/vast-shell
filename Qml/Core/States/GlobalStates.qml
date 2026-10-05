pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Vast.Translation

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Singleton {
    id: root

    readonly property string currentLanguage: TranslationManager.currentLanguage
    readonly property color drawerColors: Configs.generals.transparent ? Qt.alpha(Colours.m3Colors.m3Background, Configs.generals.alpha) : Colours.m3Colors.m3Background
    readonly property bool hasInlineReply: inlineReplyOwner !== null
    property var inlineReplyOwner: null
    property bool isBarOpen: Configs.bar.alwaysOpenBar
    property alias isCalendarOpen: panel.isCalendarOpen
    property alias isCapsLockOSDShow: root.isCapsLockOSDVisible
    readonly property bool isCapsLockOSDVisible: osd.isActive("capslock")
    property alias isClipboardOpen: panel.isClipboardOpen
    property bool isDragAndDropActive: false
    property alias isLauncherOpen: panel.isLauncherOpen
    property bool isLockscreenOpen: false
    property alias isMediaPlayerOpen: panel.isMediaPlayerOpen
    property alias isNotificationCenterOpen: panel.isNotificationCenterOpen
    property alias isNumLockOSDShow: root.isNumLockOSDVisible
    readonly property bool isNumLockOSDVisible: osd.isActive("numlock")
    property alias isQuickSettingsOpen: panel.isQuickSettingsOpen
    property alias isRecordingPanelOpen: panel.isRecordingPanelOpen
    property bool isScreenshotSelectionOpen: false
    property bool isSelectionOpen: false
    property alias isSessionOpen: panel.isSessionOpen // qmllint disable
    property alias isSettingsOpen: panel.isSettingsOpen // qmllint disable
    property alias isVolumeOSDShow: root.isVolumeOSDVisible
    readonly property bool isVolumeOSDVisible: osd.isActive("volume")
    property alias isWallpaperSwitcherOpen: panel.isWallpaperSwitcherOpen
    property alias isWeatherPanelOpen: panel.isWeatherPanelOpen
    property bool isWifiScannerOpen: true
    property string launcherQuery: ""
    property var pendingShareFiles: []
    property string previewWallpaper: ""
    property string scriptPath: `${Paths.projectRoot}/Assets/shell/screen-capture.sh`

    function closePanel(name): void {
        panel.closePanel(name);
    }
    function hideOSD(name): void {
        osd.hide(name);
        if (osd.allHidden())
            cleanupTimer.start();
    }
    function isOSDVisible(name): bool {
        return osd.isActive(name);
    }
    function openPanel(name): void {
        panel.openPanel(name);
    }
    function pauseOSD(name): void {
        osd.pause(name);
    }
    function resumeOSD(name): void {
        osd.resume(name);
    }
    function setDragAndDropActive(value, silent): void {
        if (root.isDragAndDropActive === value)
            return;
        root.isDragAndDropActive = value;
        if (!value || silent)
            return;
        ToastService.show(qsTr("Drag and drop is active. Drop files onto the island to share them."), qsTr("Drag and Drop"), "application-vnd.oasis.opendocument.text", 5000);
    }
    function setPanel(name, value): void {
        if (name === "bar") {
            root.isBarOpen = value;
            return;
        }
        panel.setPanel(name, value);
    }
    function shareFilesViaKdeConnect(files): void {
        if (!files || files.length === 0)
            return;
        root.pendingShareFiles = files;
        root.setDragAndDropActive(true, true);
    }
    function showOSD(name): void {
        osd.show(name);
    }
    function toggleOSD(name): void {
        osd.toggle(name);
    }
    function togglePanel(name): void {
        if (name === "bar") {
            root.setPanel(name, !root.isBarOpen);
            return;
        }
        panel.togglePanel(name);
    }

    OSDManager {
        id: osd
    }
    PanelManager {
        id: panel
    }
    Timer {
        id: cleanupTimer

        interval: 500
        repeat: false

        onTriggered: gc()
    }
    Variants {
        model: [
            {
                panel: "wallpaperSwitcher",
                shortcut: "wallpaperSwitcher"
            },
            {
                panel: "bar",
                shortcut: "bar"
            },
            {
                panel: "launcher",
                shortcut: "launcher"
            },
            {
                panel: "quickSettings",
                shortcut: "quickSettings"
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
                panel: "settings",
                shortcut: "settings"
            },
            {
                panel: "clipboard",
                shortcut: "clipboard"
            },
            {
                panel: "recordingPanel",
                shortcut: "recordingPanel"
            }
        ]

        delegate: PanelController {
            required property var modelData

            panelName: modelData.panel
            shortcutName: modelData.shortcut
        }
    }
    IpcHandler {
        function off(): void {
            Configs.idle.enabled = false;
        }
        function on(): void {
            Configs.idle.enabled = true;
        }
        function status(): bool {
            return Configs.idle.enabled;
        }

        target: "idle"
    }
    Connections {
        function onCapsLockChanged() {
            root.showOSD("capslock");
        }
        function onNumLockChanged() {
            root.showOSD("numlock");
        }

        target: KeylockState
    }
    Instantiator {
        model: Configs.idle.timeouts

        delegate: IdleMonitor {
            property bool fired: false
            required property var modelData
            readonly property string onResume: modelData["on-resume"] ?? ""
            readonly property string onTimeout: modelData["on-timeout"] ?? ""
            readonly property int timeoutMonitor: modelData.timeoutMonitor ?? 60

            enabled: Configs.idle.enabled
            respectInhibitors: true
            timeout: timeoutMonitor

            onIsIdleChanged: {
                if (isIdle && !fired) {
                    fired = true;
                    if (onTimeout)
                        Quickshell.execDetached({
                            command: ["sh", "-c", onTimeout]
                        });
                } else if (!isIdle && fired) {
                    fired = false;
                    if (onResume)
                        Quickshell.execDetached({
                            command: ["sh", "-c", onResume]
                        });
                }
            }
        }
    }

    component PanelController: QtObject {
        id: panelController

        property IpcHandler ipc: IpcHandler {
            function close(): void {
                root.closePanel(panelController.panelName);
            }
            function open(): void {
                root.openPanel(panelController.panelName);
            }
            function openWith(query: string): void {
                if (panelController.panelName === "launcher")
                    root.launcherQuery = query;
                root.openPanel(panelController.panelName);
            }
            function toggle(): void {
                root.togglePanel(panelController.panelName);
            }

            target: panelController.panelName
        }
        required property string panelName

        // qmllint disable
        property GlobalShortcut shortcut: GlobalShortcut {
            name: panelController.shortcutName

            onPressed: root.togglePanel(panelController.panelName)
        }
        required property string shortcutName
        // qmllint enable
    }
}
