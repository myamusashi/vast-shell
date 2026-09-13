pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors
    readonly property bool focusedWsHasFullscreen: focusedWorkspace?.hasFullscreen

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel?.wayland?.activated ? Hyprland.activeToplevel : null // qmllint disable
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    // Hyprland removed the numeric workspace `id` from IPC in favour of the
    // string addressable name (`lastIpcObject.address`). Quickshell 0.3.1 has
    // no `addressable_name` property, so identity resolves via lastIpcObject
    // with a fallback to the legacy `id` for older Hyprland builds.
    readonly property string activeWsAddress: workspaceAddress(focusedWorkspace) || "1"
    readonly property int activeWsId: workspaceNumber(focusedWorkspace) > 0 ? workspaceNumber(focusedWorkspace) : 1

    function workspaceAddress(ws: var): string {
        if (!ws)
            return "";
        const addr = ws.lastIpcObject?.address ?? ws.lastIpcObject?.addressable_name ?? null;
        if (addr !== undefined && addr !== null && addr !== "")
            return String(addr);
        if (ws.id !== undefined && ws.id !== null)
            return String(ws.id);
        return "";
    }

    function workspaceNumber(ws: var): int {
        const n = parseInt(workspaceAddress(ws), 10);
        return isNaN(n) ? -1 : n;
    }

    property var monitorData: ({})

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    signal configReloaded

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;
            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon"))
                Hyprland.refreshMonitors();
            else if (n.includes("workspace"))
                Hyprland.refreshWorkspaces();
            else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n))
                Hyprland.refreshToplevels();
        }
    }

    Instantiator {
        model: root.monitors
        delegate: QtObject {
            required property HyprlandMonitor modelData

            Component.onCompleted: {
                let data = Object.assign({}, root.monitorData);

                data[modelData.name] = {
                    availableModes: modelData.lastIpcObject.availableModes,
                    description: modelData.description,
                    refreshRate: modelData.lastIpcObject.refreshRate,
                    resolution: modelData.width + "x" + modelData.height + "@" + modelData.lastIpcObject.refreshRate,
                    scale: modelData.scale,
                    colorManagementPreset: modelData.lastIpcObject.colorManagementPreset
                };
                root.monitorData = data;
            }
        }
    }
}
