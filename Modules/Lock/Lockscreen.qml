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
}
