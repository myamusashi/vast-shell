pragma Singleton

import QtQuick
import Quickshell
import KeylockState

Singleton {
	readonly property bool capsLock: Keylock.capsLock
	readonly property bool numLock: Keylock.numLock
}
