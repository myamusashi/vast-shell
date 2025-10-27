//@ pragma UseQApplication
//@ pragma IconTheme vicinae
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
import Quickshell.Hyprland

ShellRoot {
	Bar {
		id: bar
	}
	Lockscreen {}
	Wall {}
	Session {
		id: session
	}
	App {
		id: appLauncher
	}
	Screencapture {
		id: screencapture
	}
	Notifications {}
	Dashboard {
		id: dashboard
	}
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

	GlobalShortcut {
		name: "bar"
		onPressed: bar.isBarOpen = !bar.isBarOpen
	}

	GlobalShortcut {
		name: "session"
		onPressed: session.isSessionOpen = !session.isSessionOpen
	}

	GlobalShortcut {
		name: "appLauncher"
		onPressed: appLauncher.isLauncherOpen = !appLauncher.isLauncherOpen
	}

	GlobalShortcut {
		name: "screencapture"
		onPressed: screencapture.isScreencaptureOpen = !screencapture.isScreencaptureOpen
	}

	GlobalShortcut {
		name: "dashboard"
		onPressed: dashboard.isDashboardOpen = !dashboard.isDashboardOpen
	}
}
