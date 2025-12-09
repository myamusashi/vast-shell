pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Helpers

Scope {
    property alias lock: lock

    WlSessionLock {
        id: lock

        signal unlock

        Surface {
            id: surface

            lock: lock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: lock
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            GlobalStates.hideOuterBorder = true;
            lockTimer.start();
        }

        function unlock(): void {
            lock.unlock();
        }

        function isLocked(): bool {
            return lock.locked;
        }
    }

    Timer {
        id: lockTimer

        interval: 500
        repeat: false
        onTriggered: lock.locked = true
    }
}
