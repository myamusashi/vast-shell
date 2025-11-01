pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: root

	property bool numLockState: false

	Keys.onPressed: event => {
		if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
			numLockState = true;
		}
	}

	Process {
		id: lockStateProcess

		running: true
		command: [Quickshell.shellDir + "/Assets/keystate"]
	}

	property bool capsLockState: false

	FileView {
		id: capsLockStateFile

		path: Quickshell.env("HOME") + "/.cache/keystate/capslock"
		watchChanges: true

		onFileChanged: {
			reload();
			let newState = text().trim() === "true";
			if (root.capsLockState !== newState)
				root.capsLockState = newState;
		}
	}

	FileView {
		id: numLockStateFile

		path: Quickshell.env("HOME") + "/.cache/keystate/numlock"
		watchChanges: true

		onFileChanged: {
			reload();
			let newState = text().trim() === "true";
			if (root.numLockState !== newState)
				root.numLockState = newState;
		}
	}
}
