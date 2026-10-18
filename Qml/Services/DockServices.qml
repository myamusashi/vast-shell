pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Core.Configs
import qs.Core.States
import qs.Services

Singleton {
    id: root

    readonly property var  activeToplevels: Hypr.toplevelsByWorkspace[Hypr.activeWsAddress] ?? []
    readonly property var  entriesById: {
        const acc    = {};
        const values = DesktopEntries.applications.values ?? DesktopEntries.applications;
        for (const entry of values)
            acc[entry.id] = entry;
        return acc;
    }
    readonly property real pinnedContentWidth: pinnedEntries.length === 0 ? 0 : pinnedEntries.length * (Configs.dock.iconSlot + Appearance.spacing.small * 2) + (pinnedEntries.length - 1) * Appearance.spacing.small
    readonly property var  pinnedEntries: {
        const ids = Configs.dock.pinnedApps ?? [];
        const out = [];
        for (const id of ids) {
            const entry = root.entriesById[id];
            if (entry)
                out.push(entry);
        }
        return out;
    }
    readonly property var  runningEntryIds: {
        const ids    = [];
        const values = Hypr.toplevels.values ?? Hypr.toplevels;
        for (const tl of values) {
            const entry = root.entryForToplevel(tl);
            if (entry && !ids.includes(entry.id))
                ids.push(entry.id);
        }
        return ids;
    }
    readonly property real workspaceContentWidth: activeToplevels.length === 0 ? 0 : activeToplevels.length * (Configs.dock.iconSlot + Appearance.spacing.small * 2) + (activeToplevels.length - 1) * Appearance.spacing.small

    function               activatePinned(entry: var): void {
        for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels)) {
            if (root.entryForToplevel(toplevel)?.id === entry.id) {
                root.focusToplevel(toplevel);
                return;
            }
        }
        root.launchEntry(entry);
    }
    function               closeAllWindows(entryId: string): void {
        for (const toplevel of (Hypr.toplevels.values ?? Hypr.toplevels)) {
            if (root.entryForToplevel(toplevel)?.id === entryId)
                toplevel?.wayland?.close();
        }
    }
    function               contentLength(availableWidth: real): real {
        const spacing         = Appearance.spacing.small;
        const toggleWidth     = Configs.dock.iconSlot;
        const sideWidth       = Math.max(root.pinnedContentWidth, toggleWidth);
        const sequentialWidth = root.pinnedContentWidth + root.workspaceContentWidth + toggleWidth + spacing * 4;
        const centeredWidth   = sideWidth * 2 + root.workspaceContentWidth + spacing * 4;
        return Math.min(availableWidth, Math.max(sequentialWidth, centeredWidth));
    }
    function               entryForToplevel(toplevel: var): DesktopEntry {
        return DesktopEntries.heuristicLookup(toplevel?.lastIpcObject?.class ?? "");
    }
    function               focusToplevel(toplevel: var): void {
        const workspaceNumber = Workspaces.wsNumber(toplevel?.workspace);
        if (workspaceNumber > 0)
            Workspaces.switchWorkspace(workspaceNumber);
        toplevel?.wayland?.activate();
    }
    function               isPinned(entryId: string): bool {
        return (Configs.dock.pinnedApps ?? []).includes(entryId);
    }
    function               launchEntry(entry: var): void {
        LauncherServices.launch(entry);
    }
    function               setReservedBottomSpace(value: real): void {
        GlobalStates.reservedBottomSpace = value;
    }
    function               togglePin(entryId: string): void {
        const current           = Configs.dock.pinnedApps ?? [];
        const next              = current.includes(entryId) ? current.filter(id => id !== entryId) : [...current, entryId];
        Configs.dock.pinnedApps = next;
    }
}
