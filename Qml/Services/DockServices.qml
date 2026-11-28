pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

import qs.Core.Configs
import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property var    activeToplevels: {
        const pinnedSet = new Set(pinnedEntries.map(entry => entry.id));

        return scopedToplevels.filter(toplevel => {
            const entryId = entryForToplevel(toplevel)?.id ?? "";
            return entryId === "" || !pinnedSet.has(entryId);
        });
    }
    readonly property var    entriesById: {
        const acc    = {};
        const values = DesktopEntries.applications.values ?? DesktopEntries.applications;
        for (const entry of values)
            acc[entry.id] = entry;
        return acc;
    }
    readonly property string focusedToplevelAddress: {
        if (Hypr.activeToplevel && Hypr.activeToplevel.address)
            return Hypr.activeToplevel.address;
        if (GlobalStates.isShellKeyboardGrabActive)
            return Hypr.lastActiveToplevelAddress;
        return "";
    }
    readonly property real   pinnedContentWidth: pinnedEntries.length === 0 ? 0 : pinnedEntries.length * (Configs.dock.iconSlot + Appearance.spacing.small * 2) + (pinnedEntries.length - 1) * Appearance.spacing.small
    readonly property var    pinnedEntries: {
        const ids = Configs.dock.pinnedApps ?? [];
        const out = [];
        for (const id of ids) {
            const entry = entriesById[id];
            if (entry)
                out.push(entry);
        }
        return out;
    }
    readonly property var    pinnedIds: (Configs.dock.pinnedApps ?? []).slice()
    readonly property var    runningEntryIds: {
        const ids    = [];
        const values = Hypr.toplevels.values ?? Hypr.toplevels;
        for (const tl of values) {
            const entry = entryForToplevel(tl);
            if (entry && !ids.includes(entry.id))
                ids.push(entry.id);
        }
        return ids;
    }
    readonly property var    scopedToplevels: {
        const list = Configs.dock.showAllWorkspaces ? (Hypr.toplevels.values ?? Hypr.toplevels ?? []) : (Hypr.toplevelsByWorkspace[Hypr.activeWsAddress] ?? []);

        return [...list].sort((a, b) => windowAddressKey(a) - windowAddressKey(b));
    }
    readonly property var    scopedToplevelsByEntryId: {
        const acc = {};
        for (const toplevel of scopedToplevels) {
            const entryId = entryForToplevel(toplevel)?.id ?? "";
            if (entryId === "")
                continue;
            if (acc[entryId] === undefined)
                acc[entryId] = [];
            acc[entryId].push(toplevel);
        }
        return acc;
    }
    readonly property real   workspaceContentWidth: activeToplevels.length === 0 ? 0 : activeToplevels.length * (Configs.dock.iconSlot + Appearance.spacing.small * 2) + (activeToplevels.length - 1) * Appearance.spacing.small

    function                 activatePinned(entry: var): void {
        for (const toplevel of scopedToplevels) {
            if (entryForToplevel(toplevel)?.id === entry.id) {
                focusToplevel(toplevel);
                return;
            }
        }
        if (!Configs.dock.showAllWorkspaces) {
            for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels)) {
                if (entryForToplevel(toplevel)?.id === entry.id) {
                    focusToplevel(toplevel);
                    return;
                }
            }
        }
        launchEntry(entry);
    }

    function                 closeAllWindows(entryId: string): void {
        for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels)) {
            if (entryForToplevel(toplevel)?.id === entryId)
                toplevel?.wayland?.close();
        }
    }

    function                 closeToplevel(toplevel: var): void {
        toplevel?.wayland?.close();
    }

    function                 contentLength(availableWidth: real): real {
        const spacing      = Appearance.spacing.small;
        const toggleWidth  = Configs.dock.iconSlot + spacing * 2;
        const contentWidth = pinnedContentWidth + workspaceContentWidth + toggleWidth + spacing * 4 + 2;
        return Math.min(availableWidth, contentWidth);
    }

    function                 entryForToplevel(toplevel: var): DesktopEntry {
        return DesktopEntries.heuristicLookup(toplevel?.lastIpcObject?.class ?? "");
    }

    function                 focusToplevel(toplevel: var): void {
        const workspaceNumber = Workspaces.wsNumber(toplevel?.workspace);
        if (workspaceNumber > 0)
            Workspaces.switchWorkspace(workspaceNumber);
        toplevel?.wayland?.activate();
    }

    function                 isToplevelFloating(toplevel: var): bool {
        return toplevel?.lastIpcObject?.floating === true;
    }

    function                 isToplevelFullscreen(toplevel: var): bool {
        const ipcFullscreen = toplevel?.lastIpcObject?.fullscreen;
        return toplevel?.wayland?.fullscreen === true || (ipcFullscreen !== undefined && ipcFullscreen !== null && ipcFullscreen !== 0 && ipcFullscreen !== false);
    }

    function                 launchEntry(entry: var): void {
        LauncherServices.launch(entry);
    }

    function                 normalizedAddress(address: string): string {
        if (!address)
            return "";
        return address.startsWith("0x") ? address : ("0x" + address);
    }

    function                 reorderPinned(entryId: string, targetIndex: int): void {
        const current   = (Configs.dock.pinnedApps ?? []).slice();
        const fromIndex = current.indexOf(entryId);
        if (fromIndex < 0)
            return;

        const validIds = pinnedEntries.map(entry => entry.id);
        if (validIds.length === 0)
            return;

        const clampedTarget = Math.max(0, Math.min(targetIndex, validIds.length - 1));
        const targetId      = validIds[clampedTarget];
        if (!targetId || targetId === entryId)
            return;

        const targetRawIndex = current.indexOf(targetId);
        if (targetRawIndex < 0)
            return;

        current.splice(fromIndex, 1);
        current.splice(targetRawIndex, 0, entryId);
        Configs.dock.pinnedApps = current;
    }

    function                 scopedToplevelsForEntry(entryId: string): var {
        if (entryId === "")
            return [];
        return scopedToplevelsByEntryId[entryId] ?? [];
    }

    function                 setReservedBottomSpace(value: real): void {
        GlobalStates.reservedBottomSpace = value;
    }

    function                 toggleFloating(toplevel: var): void {
        const address = normalizedAddress(toplevel?.address ?? "");
        if (address === "")
            return;
        Hypr.dispatch(`hl.dsp.window.float({ window = "address:${address}", action = "toggle" })`);
        Hyprland.refreshToplevels();
    }

    function                 toggleFullscreen(toplevel: var): void {
        const address = normalizedAddress(toplevel?.address ?? "");
        if (address !== "") {
            Hypr.dispatch(`hl.dsp.window.fullscreen({ window = "address:${address}", action = "toggle", mode = "fullscreen" })`);
            Hyprland.refreshToplevels();
            return;
        }
        if (toplevel?.wayland)
            toplevel.wayland.fullscreen = !toplevel.wayland.fullscreen;
    }

    function                 togglePin(entryId: string): void {
        const current           = Configs.dock.pinnedApps ?? [];
        const next              = current.includes(entryId) ? current.filter(id => id !== entryId) : [...current, entryId];
        Configs.dock.pinnedApps = next;
    }

    function                 windowAddressKey(toplevel: var): int {
        const parsed = parseInt(toplevel?.address ?? "", 16);

        return isNaN(parsed) ? 0 : parsed;
    }
}
