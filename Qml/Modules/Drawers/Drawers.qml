import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Modules.Drawers
import qs.Core.Configs
import qs.Core.States
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
        HyprlandWindow.visibleMask: childRegions.instance // qmllint disable
        mask: Region {
            regions: childRegions.instances
            item: screenBorder.border
            intersection: Intersection.Combine
        }

        Variants {
            id: childRegions

            model: window.contentItem.children
            delegate: Region {
                required property Item modelData
                item: modelData
                intersection: Intersection.Xor
            }
        }

        ScreenBorder {
            id: screenBorder

            window: window
        }

        Launcher {
            id: launcher
        }

        Bar {
            id: bar
        }

        Clipboard {
            id: clipboard
        }

        Calendar {
            id: calendar
            anchors.topMargin: screenBorder.border.borderTop
        }

        QuickSettings {
            id: quickSettings
        }

        Session {
            id: session
        }

        WallpaperSelector {}

        CaptureScreenVideo {}

        OSD {
            id: osd
        }

        BrightnessOsd {
            id: brightnessOsd
        }

        Notifications {
            id: notif
            anchors.topMargin: screenBorder.border.borderTop
        }

        Weathers {
            anchors.topMargin: screenBorder.border.borderTop
        }

        Volume {
            id: volume
            anchors.rightMargin: session.width + Configs.generals.outerBorderSize
        }
    }
}
