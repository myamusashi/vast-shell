pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property HyprlandToplevel activeToplevel: Hyprland.activeToplevel?.wayland?.activated ? Hyprland.activeToplevel : null // qmllint disable
    readonly property string activeWsAddress: {
        const monAddr = focusedMonitor?.activeWorkspace?.address ?? focusedMonitor?.lastIpcObject.activeWorkspace?.address ?? "";
        if (monAddr !== undefined && monAddr !== null && monAddr !== "")
            return String(monAddr);
        return workspaceAddress(focusedWorkspace) || "1";
    }
    readonly property int activeWsId: {
        const n = parseInt(activeWsAddress, 10);
        return isNaN(n) || n <= 0 ? 1 : n;
    }
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property bool focusedWsHasFullscreen: focusedWorkspace?.hasFullscreen
    property var monitorData: ({})
    readonly property var monitors: Hyprland.monitors
    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces

    signal configReloaded

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }
    function monitorFor(screen: ShellScreen): HyprlandMonitor {
        return Hyprland.monitorFor(screen);
    }

    // Address of the workspace a toplevel lives on. The resolved workspace
    // object carries `address` directly; the toplevel's own IPC payload covers
    // objects not yet refreshed, with legacy `id` fallbacks for old builds.
    function toplevelWorkspaceAddress(tl: var): string {
        if (!tl)
            return "";
        const objAddr = tl.workspace?.address ?? "";
        const ipcWs = tl.lastIpcObject?.workspace;
        if (ipcWs) {
            const addr = ipcWs.address ?? ipcWs.addressable_name ?? null;
            if (addr !== undefined && addr !== null && addr !== "")
                return String(addr);
            if (ipcWs.id !== undefined && ipcWs.id !== null && ipcWs.id !== -1)
                return String(ipcWs.id);
        }
        const wname = tl.workspace?.name ?? "";
        if (wname !== "") {
            const n = parseInt(wname, 10);
            if (!isNaN(n))
                return String(n);
            return wname;
        }
        return workspaceAddress(tl.workspace);
    }
    function workspaceAddress(ws: var): string {
        if (!ws)
            return "";
        const addr = ws.address ?? ws.lastIpcObject?.address ?? null;
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

    Connections {
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

        target: Hyprland
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
