//@ pragma UseQApplication
//@ pragma IconTheme la-capitaine-icon-theme
//@ pragma Env QS_NO_RELOAD_POPUP=1

import qs.Modules.Lock
import qs.Modules.Bar
import qs.Modules.Wallpaper
import qs.Modules.Session
import qs.Modules.Launcher
import qs.Modules.Notifications
import qs.Modules.Dashboard
// import qs.Modules.BigClock
import qs.Modules.OSD
import qs.Modules.Overview

import QtQuick
import Quickshell

ShellRoot {
	Bar {}
	Lockscreen {}
	Wall {}
	Session {}
	App {}
	Screencapture {}
	Notifications {}
	Dashboard {}
	// Clock {}
	OSD {}
	Overview {}

	Connections {
		function onReloadCompleted() {
			Quickshell.inhibitReloadPopup();
		}

		function onReloadFailed() {
			Quickshell.inhibitReloadPopup();
		}

		target: Quickshell
	}
}
