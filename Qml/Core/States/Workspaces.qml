pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: hyprland

    property int                     maxWorkspace: findMaxId()
    property list<HyprlandWorkspace> workspaces: sortWorkspaces(Hyprland.workspaces.values)

    function                         findMaxId(): int {
        let maxId = 1;
        for (const w of workspaces)
            maxId = Math.max(maxId, wsNumber(w));
        return maxId;
    }
    function                         focusToplevel(w: int, address: string): void {
        if (address !== undefined && address !== null && address !== "")
            Hyprland.dispatch(`hl.dsp.focus({window = ${address}})`);
        else
            switchWorkspace(w);
    }
    function                         sortWorkspaces(ws) {
        return [...ws].sort((a, b) => wsNumber(a) - wsNumber(b));
    }
    function                         switchWorkspace(w: int): void {
        Hyprland.dispatch(`hl.dsp.focus({workspace = ${w}})`);
    }
    function                         wsNumber(ws: var): int {
        const n = parseInt(ws?.address ?? ws?.lastIpcObject?.address ?? ws?.id ?? "", 10);
        return isNaN(n) ? -1 : n;
    }

    Connections {
        function onRawEvent(event) {
            let eventName = event.name;

            switch (eventName) {
            case "createworkspacev2":
                {
                    hyprland.workspaces   = hyprland.sortWorkspaces(Hyprland.workspaces.values);
                    hyprland.maxWorkspace = hyprland.findMaxId();
                }
                break;
            case "destroyworkspacev2":
                {
                    hyprland.workspaces   = hyprland.sortWorkspaces(Hyprland.workspaces.values);
                    hyprland.maxWorkspace = hyprland.findMaxId();
                }
                break;
            }
        }

        target: Hyprland
    }
}
