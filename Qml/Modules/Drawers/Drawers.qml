import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "Clipboard"
import "Dashboard"
import "Launcher"
import "QuickSettings"
import "Notifications"
import "Session"
import "WallpaperSelector"
import "Weather"
import "OSD"
import "Bar"
import "Volume"
import "Brightness"
import "CaptureScreen"
import "Dock"

Variants {
    model: Quickshell.screens
    delegate: PanelWindow {
        id: window

        required property ShellScreen modelData

        readonly property bool        barOpen: FocusedMonitor.isOnFocusedMonitor(modelData.name) && GlobalStates.isBarOpen
        readonly property bool        dockVisible: FocusedMonitor.isOnFocusedMonitor(modelData.name) && Configs.dock.enabled
        readonly property bool        needFocusKeyboard: {
            if (GlobalStates.isLauncherOpen)
                return true;
            if (GlobalStates.isSessionOpen && !session.showConfirmDialog)
                return true;
            if (GlobalStates.isWallpaperSwitcherOpen)
                return true;
            if (GlobalStates.isClipboardOpen)
                return true;
            if (GlobalStates.hasInlineReply)
                return true;
            if (GlobalStates.isAddTodoListOpen)
                return true;
            if (GlobalStates.isEditTodoListOpen)
                return true;
            return false;
        }

        property bool                 yieldKeyboardFocus: false

        function                      reclaimKeyboardFocus(): void {
            window.yieldKeyboardFocus = true;
            Qt.callLater(() => {
                window.yieldKeyboardFocus = false;
            });
        }

        HyprlandWindow.visibleMask: window.mask // qmllint disable
        WlrLayershell.keyboardFocus: needFocusKeyboard && !yieldKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "shell:drawers"
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        screen: modelData
        mask: Region {
            regions: maskRegions.instances
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        Variants {
            id: maskRegions

            model: screenBorder.collectMaskItems()
            delegate: Region {
                required property Item modelData

                intersection: Intersection.Combine
                item: modelData.visible ? modelData : null
            }
        }

        ScreenBorder {
            id: screenBorder

            barHeight: Configs.bar.barHeight
            dockHeight: window.dockVisible ? Configs.dock.dockHeight : 0
            color: GlobalStates.drawerColors
            enableOuterBorder: Configs.generals.enableOuterBorder
            isBarOpen: GlobalStates.isBarOpen
            isDockVisible: window.dockVisible
            isFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(window.modelData.name)
            outerBorderSize: Configs.generals.outerBorderSize
            window: window.modelData

            Launcher {}

            Clipboard {}

            Dashboard {}

            QuickSettings {}

            Session {
                id: session
            }

            BrightnessOsd {}

            OSD {}

            Volume {
                session: session
            }

            CaptureScreen {}

            Notifications {}

            WallpaperSelector {}

            Weathers {}

            // Must stay last so the dock paints above the drawer shapes

            Dock {
                id: dock
                border: screenBorder
                parentWindow: window
            }
        }

        Bar {
            id: bar

            border: screenBorder
            open: window.barOpen
        }
    }
}
