pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.Core.Utils
import qs.Services
import qs.Services.Hyprland

Singleton {
    id: root

    // stored mirrors monitor.json; pending holds the working draft.
    // Both are maps keyed by monitor identity (description, falling back to model).
    readonly property bool dirty: canonical(pending) !== canonical(stored)
    readonly property var  liveMonitors: Hyprland.monitors?.values ?? []
    readonly property bool loaded: monitorFile.loaded

    property var           pending: ({})
    property var           stored: ({})

    FileView {
        id: monitorFile

        path: Paths.shellDir + "/monitor.json"
        watchChanges: false
        onLoaded: root.resetFromDisk()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                ToastService.show(qsTr("Failed to read monitor settings: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaveFailed: err => ToastService.show(qsTr("Failed to save monitor settings: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000)
        onSaved: HyprlandSetupServices.reloadHyprland()

        JsonAdapter { // qmllint disable
            id: adapter

            property var monitors: ({})
        }
    }

    // Display list: live monitors first, then stored entries not currently connected.

    function               entryFor(monitor: HyprlandMonitor, key: string): var { // qmllint disable
        if (pending[key] !== undefined)
            return pending[key];
        if (stored[key] !== undefined)
            return deepCopy(stored[key]);
        return seedEntry(monitor);
    }

    function               identityOf(monitor: HyprlandMonitor): string { // qmllint disable
        const description = monitor?.description ?? "";
        if (description !== "")
            return description;
        return monitor?.lastIpcObject.model ?? monitor?.name ?? "";
    }

    function               liveMonitorFor(key: string): HyprlandMonitor { // qmllint disable
        return liveMonitors.find(monitor => identityOf(monitor) === key) ?? null;
    }

    function               monitorList(): var {
        const result = [];
        const seen   = {};
        for (const monitor of liveMonitors) {
            const key = identityOf(monitor);
            seen[key] = true;
            result.push({
                entry: entryFor(monitor, key),
                key: key,
                live: true
            });
        }
        for (const key of Object.keys(stored)) {
            if (seen[key])
                continue;
            result.push({
                entry: pending[key] ?? deepCopy(stored[key]),
                key: key,
                live: false
            });
        }
        for (const key of Object.keys(pending)) {
            if (seen[key] || stored[key] !== undefined)
                continue;
            result.push({
                entry: pending[key],
                key: key,
                live: false
            });
        }
        return result;
    }

    function               seedEntry(monitor: HyprlandMonitor): var { // qmllint disable
        const ipc  = monitor?.lastIpcObject ?? {};
        const mode = currentMode(monitor);
        return {
            bitdepth: 8,
            cm: ipc.colorManagementPreset ?? "srgb",
            disabled: false,
            height: mode.height,
            icc: "",
            lastConnector: monitor?.name ?? "",
            model: ipc.model ?? "",
            refreshRate: mode.refreshRate,
            sdrbrightness: 1.0,
            sdrsaturation: 1.0,
            scale: monitor?.scale ?? 1,
            transform: ipc.transform ?? 0,
            width: mode.width,
            x: monitor?.x ?? 0,
            y: monitor?.y ?? 0
        };
    }

    // Current mode from availableModes. Monitors list several modes with the same
    // resolution at different refresh rates (sometimes duplicate pixel clocks), so
    // the running refresh rate must decide, not the first size match.

    function               currentMode(monitor: HyprlandMonitor): var { // qmllint disable
        const modes = (monitor?.lastIpcObject.availableModes ?? []).map(mode => parseModeString(mode)).filter(mode => mode !== null);
        if (modes.length === 0)
            return {
                height: monitor?.height ?? 1080,
                refreshRate: monitor?.lastIpcObject.refreshRate ?? 60.0,
                width: monitor?.width ?? 1920
            };
        const width   = monitor?.width ?? -1;
        const height  = monitor?.height ?? -1;
        const refresh = monitor?.lastIpcObject.refreshRate ?? -1;
        const running = modes.find(mode => mode.width === width && mode.height === height && Math.abs(mode.refreshRate - refresh) < 0.05);
        if (running)
            return running;
        const byRefresh = modes.find(mode => Math.abs(mode.refreshRate - refresh) < 0.05);
        if (byRefresh)
            return byRefresh;
        const bySize = modes.find(mode => mode.width === width && mode.height === height);
        return bySize ?? modes[0];
    }

    function               parseModeString(mode: string): var {
        const match = /^(\d+)x(\d+)@([\d.]+)(Hz)?$/.exec(mode.trim());
        if (!match)
            return null;
        return {
            height: parseInt(match[2], 10),
            refreshRate: parseFloat(match[3]),
            width: parseInt(match[1], 10)
        };
    }

    function               revertMonitor(key: string): void {
        const next = Object.assign({}, pending);
        if (stored[key] !== undefined)
            next[key] = deepCopy(stored[key]);
        else
            delete next[key];
        pending = next;
    }

    function               setField(key: string, field: string, value: var): void {
        const monitor    = liveMonitorFor(key);
        const base       = pending[key] ?? (stored[key] !== undefined ? deepCopy(stored[key]) : (monitor ? seedEntry(monitor) : {}));
        const next       = Object.assign({}, pending);
        next[key]        = Object.assign({}, base);
        next[key][field] = value;
        pending          = next;
    }

    // Writes the whole draft into monitor.json, then reloads Hyprland (onSaved).

    function               apply(): void {
        resolveOverlaps();
        stored           = deepCopy(pending);
        adapter.monitors = deepCopy(stored);
        monitorFile.writeAdapter();
    }

    // Hyprland refuses to register overlapping monitors, so nothing overlapping
    // may ever reach monitor.json. Iterated until stable: clamping one monitor
    // can push it into another.

    function               deepCopy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? {}));
    }

    function               discardAll(): void {
        pending = deepCopy(stored);
    }

    function               resetFromDisk(): void {
        stored  = deepCopy(adapter.monitors ?? {});
        pending = deepCopy(stored);
    }

    function               resolveOverlaps(): void {
        for (let pass = 0; pass < 4; pass++) {
            let moved = false;
            for (const rect of root.drawableRects()) {
                const snapped = root.snappedPosition(rect.key, rect.x, rect.y, 0);
                if (snapped.x !== rect.x || snapped.y !== rect.y) {
                    root.setField(rect.key, "x", snapped.x);
                    root.setField(rect.key, "y", snapped.y);
                    moved = true;
                }
            }
            if (!moved)
                return;
        }
    }

    // Stable string form (sorted keys) so drafts and parsed files compare order-independently.

    function               canonical(value: var): string {
        if (value === null || value === undefined)
            return "null";
        if (Array.isArray(value))
            return `[${value.map(item => canonical(item)).join(",")}]`;
        if (typeof value === "object") {
            const keys = Object.keys(value).sort();
            return `{${keys.map(key => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`;
        }
        return JSON.stringify(value);
    }

    // Identities shared by more than one connected monitor: desc: rules would hit both.

    function               duplicateIdentities(): var {
        const counts = {};
        for (const monitor of liveMonitors) {
            const key   = identityOf(monitor);
            counts[key] = (counts[key] ?? 0) + 1;
        }
        return Object.keys(counts).filter(key => counts[key] > 1);
    }

    function               transformSwapsDimensions(transform: int): bool {
        return transform === 1 || transform === 3 || transform === 5 || transform === 7;
    }

    // Logical (post-scale, transform-aware) size used by the layout canvas.

    function               logicalSize(entry: var): var {
        const scale = (typeof entry.scale === "number" && entry.scale > 0) ? entry.scale : 1;
        let width   = (entry.width ?? 1920) / scale;
        let height  = (entry.height ?? 1080) / scale;
        if (transformSwapsDimensions(entry.transform ?? 0)) {
            const swap = width;
            width      = height;
            height     = swap;
        }
        return {
            height: height,
            width: width
        };
    }

    // Layout rectangles of connected, enabled monitors only. Stored entries for
    // monitors that are not currently connected have no real geometry.

    function               drawableRects(): var {
        const rects = [];
        for (const monitor of liveMonitors) {
            const key   = identityOf(monitor);
            const entry = entryFor(monitor, key);
            if (entry.disabled)
                continue;
            const size = logicalSize(entry);
            rects.push({
                height: size.height,
                key: key,
                label: monitor.name,
                width: size.width,
                x: entry.x ?? 0,
                y: entry.y ?? 0
            });
        }
        return rects;
    }

    function               monitorItemForKey(key: string): var { // qmllint disable
        return monitorList().find(item => item.key === key) ?? null;
    }

    function               rectForKey(key: string): var { // qmllint disable
        return drawableRects().find(rect => rect.key === key) ?? null;
    }

    // Snap the dragged top-left corner to other rects' edges and the origin, then
    // resolve any overlap by clamping along the dominant drag axis. Hyprland
    // refuses to register overlapping monitors, so overlap must never survive.

    function               snappedPosition(key: string, x: real, y: real, threshold: real): var { // qmllint disable
        const others = drawableRects().filter(rect => rect.key !== key);
        const me     = drawableRects().find(rect => rect.key === key);
        if (!me)
            return {
                x: x,
                y: y
            };
        const xCandidates = [0];
        const yCandidates = [0];
        for (const rect of others) {
            xCandidates.push(rect.x, rect.x + rect.width, rect.x - me.width);
            yCandidates.push(rect.y, rect.y + rect.height, rect.y - me.height);
        }
        let px    = x;
        let py    = y;
        let bestX = threshold;
        let bestY = threshold;
        for (const candidate of xCandidates) {
            const distance = Math.abs(x - candidate);
            if (distance < bestX) {
                bestX = distance;
                px    = candidate;
            }
        }
        for (const candidate of yCandidates) {
            const distance = Math.abs(y - candidate);
            if (distance < bestY) {
                bestY = distance;
                py    = candidate;
            }
        }
        for (let pass = 0; pass < others.length + 1; pass++) {
            let resolved = true;
            for (const rect of others) {
                const overlaps = px < rect.x + rect.width && px + me.width > rect.x && py < rect.y + rect.height && py + me.height > rect.y;
                if (!overlaps)
                    continue;
                resolved         = false;
                const horizontal = Math.abs(px - x) >= Math.abs(py - y);
                if (horizontal)
                    px = (x <= rect.x) ? rect.x - me.width : rect.x + rect.width;
                else
                    py = (y <= rect.y) ? rect.y - me.height : rect.y + rect.height;
            }
            if (resolved)
                break;
        }
        return {
            x: Math.round(px),
            y: Math.round(py)
        };
    }
}
