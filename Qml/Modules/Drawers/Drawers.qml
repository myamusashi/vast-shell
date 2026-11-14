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
import "QuickSettings"
import "Notifications"
import "Session"
import "Weather"
import "OSD"
import "Bar"
import "Volume"
import "Brightness"
import "CaptureScreen"
import "BottomDrawers"
import "BottomDrawers/Dock"

Variants {
    model: Quickshell.screens
    delegate: PanelWindow {
        id: panelWindow

        required property ShellScreen modelData

        readonly property bool        barOpen: FocusedMonitor.isOnFocusedMonitor(modelData.name) && GlobalStates.isBarOpen
        readonly property bool        dockVisible: FocusedMonitor.isOnFocusedMonitor(modelData.name) && Configs.dock.enabled
        readonly property bool        needFocusKeyboard: {
            if (GlobalStates.isLauncherOpen)
                return true;
            if (GlobalStates.isSessionOpen && !sessionDrawer.showConfirmDialog)
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
            yieldKeyboardFocus = true;
            Qt.callLater(() => {
                yieldKeyboardFocus = false;
            });
        }

        color: "transparent"
        WlrLayershell.keyboardFocus: needFocusKeyboard && !yieldKeyboardFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: LayerNamespaces.drawers
        exclusionMode: ExclusionMode.Ignore
        screen: modelData
        mask: maskInstances
        BackgroundEffect.blurRegion: maskInstances
        HyprlandWindow.visibleMask: maskInstances

        Region {
            id: maskInstances

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
            dockHeight: panelWindow.dockVisible ? Configs.dock.dockHeight : 0
            color: GlobalStates.drawerColors
            enableOuterBorder: GlobalStates.isLockscreenOpen ? 0 : Configs.generals.enableOuterBorder
            isBarOpen: GlobalStates.isBarOpen
            isDockVisible: panelWindow.dockVisible
            isFocusedMonitor: FocusedMonitor.isOnFocusedMonitor(panelWindow.modelData.name)
            outerBorderSize: Configs.generals.outerBorderSize
            window: panelWindow.modelData
            visible: !GlobalStates.isLockscreenOpen

            Clipboard {
                id: clipboardDrawer
            }

            Dashboard {
                id: dashboardDrawer
            }

            QuickSettings {
                id: quickSettingsDrawer
            }

            Session {
                id: sessionDrawer
            }

            BrightnessOsd {
                id: brightnessOsdDrawer
            }

            OSD {
                id: osdDrawer
            }

            Volume {
                id: volumeDrawer
                session: sessionDrawer
            }

            CaptureScreen {
                id: captureScreenDrawer
            }

            Notifications {
                id: notificationsDrawer
            }

            Weathers {
                id: weathersDrawer
            }

            PanelDrawer {
                id: panelDrawer

                border: screenBorder
                depthRatio: dock.panelDepthRatio
                dockWidth: dock.dockWidth
                isPanelMerged: dock.isPanelMerged
                lengthRatio: dock.panelLengthRatio
            }

            Dock {
                id: dock
                border: screenBorder
                panelVisible: panelDrawer.visible
                parentWindow: panelWindow
            }
        }

        Bar {
            id: bar

            border: screenBorder
            open: panelWindow.barOpen
        }
    }
}
