pragma Singleton

import Quickshell
import Quickshell.Services.Polkit
import QtQuick

Singleton {
    readonly property Agent agent: Agent {}
    component Agent: PolkitAgent {
        id: polkitAgent
    }
}
