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

        readonly property bool barOpen: FocusedMonitor.isOnFocusedMonitor(modelData.name) && GlobalStates.isBarOpen
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

        HyprlandWindow.visibleMask: window.mask // qmllint disable

        WlrLayershell.keyboardFocus: needFocusKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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
            color: GlobalStates.drawerColors
            enableOuterBorder: Configs.generals.enableOuterBorder
            isBarOpen: GlobalStates.isBarOpen
            isFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(window.modelData.name)
            outerBorderSize: Configs.generals.outerBorderSize
            window: window.modelData

            Launcher {
            }
            Clipboard {
            }
            Calendar {
            }
            QuickSettings {
            }
            Session {
                id: session
            }
            BrightnessOsd {
            }
            OSD {
            }
            Volume {
                session: session
            }
            CaptureScreenVideo {
            }
            Notifications {
            }
            WallpaperSelector {
            }
            Weathers {
            }
        }
        Bar {
            id: bar

            border: screenBorder
            open: window.barOpen
        }
    }
}
