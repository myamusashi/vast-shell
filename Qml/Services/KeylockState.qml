pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Keylock

Singleton {
    id: root

    readonly property bool capsLock: Keylock.capsLock
    readonly property bool numLock: Keylock.numLock

    IpcHandler {

        function capslock(): bool {
            return root.capsLock;
        }

        function numlock(): bool {
            return root.numLock;
        }

        target: "keylock"
    }
}
