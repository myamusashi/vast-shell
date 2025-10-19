pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // This is the easiest way to get lock state with a little bit performance usage
    Process {
        id: lockStateProcess

        running: true
        command: [`${Quickshell.shellDir}/Assets/lockState`]
    }

    property bool capsLockState: false
    property bool numLockState: false

    FileView {
        id: capsLockStateFile

        path: Quickshell.env("HOME") + "/.cache/hyprlandKeyState/capslockState"
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

        path: Quickshell.env("HOME") + "/.cache/hyprlandKeyState/numlockState"
        watchChanges: true
        onFileChanged: {
            reload();
            let newState = text().trim() === "true";
            if (root.numLockState !== newState)
            root.numLockState = newState;
        }
    }
}
