import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

import "Calendar"
import "Clipboard"
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
import "CaptureScreenVideo"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }

        required property ShellScreen modelData
        readonly property bool needFocusKeyboard: {
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
            return false;
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "shell:drawers"
        WlrLayershell.keyboardFocus: needFocusKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        HyprlandWindow.visibleMask: window.mask // qmllint disable

        mask: Region {
            regions: maskRegions.instances
        }

        Variants {
            id: maskRegions
            model: screenBorder.collectMaskItems()
            delegate: Region {
                required property Item modelData
                item: modelData
                intersection: Intersection.Combine
            }
        }

        readonly property bool barOpen: FocusedMonitor.isOnFocusedMonitor(modelData.name) && GlobalStates.isBarOpen

        ScreenBorder {
            id: screenBorder

            window: window.modelData
            color: GlobalStates.drawerColors
            isFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(window.modelData.name)
            isBarOpen: GlobalStates.isBarOpen
            barHeight: Configs.bar.barHeight
            enableOuterBorder: Configs.generals.enableOuterBorder
            outerBorderSize: Configs.generals.outerBorderSize

            Launcher {}
            Clipboard {}
            Calendar {}
            QuickSettings {}
            Session {
                id: session
            }
            BrightnessOsd {}
            OSD {}
            Volume {
                session: session
            }
            CaptureScreenVideo {}
            Notifications {}
            WallpaperSelector {}
            Weathers {}
        }

        Bar {
            id: bar
            border: screenBorder
            open: window.barOpen
        }
    }
}
