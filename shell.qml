//@ pragma UseQApplication
//@ pragma IconTheme WhiteSur-dark
//@ pragma Env QS_NO_RELOAD_POPUP=1
import qs.Modules.Lock
import qs.Modules.Bar
import qs.Modules.Wallpaper
import qs.Modules.Session
import qs.Modules.Launcher
import qs.Modules.Notifications
import qs.Modules.RecordPanel
import qs.Modules.OSD
import qs.Modules.Overview
import qs.Modules.Polkit
import qs.Modules

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.Components

ShellRoot {
	Bar {
	       id: bar
	   }
    Lockscreen {}
	Wall {}
	RecordPanel {}
    Polkit {}
    Screencapture {
        id: screencapture
	}
	Wrapper {}
    Overview {}

    Connections {
        function onReloadCompleted() {
            Quickshell.inhibitReloadPopup()
        }

        function onReloadFailed() {
            Quickshell.inhibitReloadPopup()
        }

        target: Quickshell
	}

    GlobalShortcut {
        name: "screencapture"
        onPressed: screencapture.isOpen = !screencapture.isOpen
    }
}
