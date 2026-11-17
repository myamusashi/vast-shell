pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Core.States

Scope {
    property alias lock: sessionLock

    WlSessionLock {
        id: sessionLock

        signal unlock

        Surface {
            id: surface

            lock: sessionLock
            pam: pamAuth
        }
    }

    Pam {
        id: pamAuth

        lock: sessionLock
    }

    IpcHandler {

        function isLocked(): bool {
            return sessionLock.locked;
        }

        function lock(): void {
            sessionLock.locked            = true;
            GlobalStates.isLockscreenOpen = true;
        }

        function unlock(): void {
            sessionLock.unlock();
        }

        target: "lock"
    }
}
