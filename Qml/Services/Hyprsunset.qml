pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool isNightModeOn: false

    function      down(): void {
        isNightModeOn          = false;
        killHyprsunset.running = true;
    }
    function      up(): void {
        isNightModeOn      = true;
        hyprsunset.running = true;
    }

    Process {
        id: hyprsunset

        command: ["sh", "-c", "hyprsunset -t 3000"]
    }

    Process {
        id: killHyprsunset

        command: ["sh", "-c", "kill $(pgrep hyprsunset)"]
    }
}
