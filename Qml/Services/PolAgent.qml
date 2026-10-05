pragma Singleton

import QtQuick

import Quickshell
import Quickshell.Services.Polkit

Singleton {
    readonly property Agent agent: Agent {
    }

    function cancel(): void {
        agent.flow?.cancelAuthenticationRequest(); // qmllint disable
    }
    function submit(response: string): void {
        agent.flow?.submit(response); // qmllint disable
    }

    component Agent: PolkitAgent {
        id: polkitAgent
    }
}
