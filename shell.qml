//@ pragma UseQApplication
import qs.Modules.Lock
import qs.Modules.Bar
import qs.Modules.Wallpaper
import qs.Modules.Session

import QtQuick
import Quickshell

ShellRoot {
	Bar {}
	Lock {}
	Wall {}
	Session {}

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
