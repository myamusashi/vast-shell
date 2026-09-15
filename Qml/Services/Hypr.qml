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
    // TODO: replace this workaround once quickshell exposes an `address` property.
    //
    // Hyprland removed the numeric workspace `id` from IPC in favour of the
    // string addressable name (`lastIpcObject.address`). Quickshell 0.3.1 has
    // no `addressable_name` property, so identity resolves via lastIpcObject
    // with a fallback to the legacy `id` for older Hyprland builds.
    // Active workspace address resolved from the focused monitor's IPC payload
    // (`activeWorkspace.address`). The HyprlandWorkspace object itself is
    // unreliable on Quickshell 0.3.1 + new Hyprland: refreshWorkspaces() matches
    // by the removed `id` key, so all workspaces alias to id 0 and their
    // lastIpcObject gets overwritten by whichever entry was parsed last.
    readonly property string activeWsAddress: {
        const monAddr = focusedMonitor?.lastIpcObject.activeWorkspace?.address ?? "";
        if (monAddr !== undefined && monAddr !== null && monAddr !== "")
            return String(monAddr);
        return workspaceAddress(focusedWorkspace) || "1";
    }
    readonly property int activeWsId: {
        const n = parseInt(activeWsAddress, 10);
        return isNaN(n) || n <= 0 ? 1 : n;
    }

    function workspaceAddress(ws: var): string {
        if (!ws)
            return "";
        const addr = ws.lastIpcObject?.address;
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

    // Address of the workspace a toplevel lives on. The resolved workspace
    // object is kept current by Hyprland events (movewindowv2, ...), so its
    // name wins while present; the toplevel's own IPC payload covers the
    // gaps (e.g. object deleted by the aliased workspace refresh).
    function toplevelWorkspaceAddress(tl: var): string {
        if (!tl)
            return "";
        const wname = tl.workspace?.name ?? "";
        if (wname !== "") {
            const n = parseInt(wname, 10);
            if (!isNaN(n))
                return String(n);
        }
        const ipcWs = tl.lastIpcObject?.workspace;
        if (ipcWs) {
            const addr = ipcWs.address ?? ipcWs.addressable_name ?? null;
            if (addr !== undefined && addr !== null && addr !== "")
                return String(addr);
            if (ipcWs.id !== undefined && ipcWs.id !== null && ipcWs.id !== -1)
                return String(ipcWs.id);
        }
        if (wname !== "")
            return wname;
        return workspaceAddress(tl.workspace);
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
