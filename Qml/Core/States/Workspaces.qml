pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: hyprland

    property list<HyprlandWorkspace> workspaces: sortWorkspaces(Hyprland.workspaces.values)
    property int maxWorkspace: findMaxId()

    // Numeric value of the workspace address (e.g. "1"). Non-numeric
    // (named/special) workspaces yield -1 so they sort before numbered ones,
    // matching the old negative-id ordering.
    function wsNumber(ws: var): int {
        const n = parseInt(ws?.address ?? ws?.lastIpcObject?.address ?? ws?.id ?? "", 10);
        return isNaN(n) ? -1 : n;
    }

    function sortWorkspaces(ws) {
        return [...ws].sort((a, b) => wsNumber(a) - wsNumber(b));
    }

    function switchWorkspace(w: int): void {
        Hyprland.dispatch(`hl.dsp.focus({workspace = ${w}})`);
    }

    function findMaxId(): int {
        let maxId = 1;
        for (const w of workspaces)
            maxId = Math.max(maxId, wsNumber(w));
        return maxId;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            let eventName = event.name;

            switch (eventName) {
            case "createworkspacev2":
                {
                    hyprland.workspaces = hyprland.sortWorkspaces(Hyprland.workspaces.values);
                    hyprland.maxWorkspace = hyprland.findMaxId();
                }
                break;
            case "destroyworkspacev2":
                {
                    hyprland.workspaces = hyprland.sortWorkspaces(Hyprland.workspaces.values);
                    hyprland.maxWorkspace = hyprland.findMaxId();
                }
                break;
            }
        }
    }
}
