pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Core.Utils
import qs.Services
import qs.Services.Hyprland

Singleton {
    id: root

    readonly property bool loaded: generalsFile.loaded

    property var           pending: ({})
    property var           stored: ({})

    function               applyCategory(category: string): void {
        const draft = pending[category];
        if (draft === undefined)
            return;

        const next   = deepCopy(root.stored);
        const nested = unflatten(draft);
        if (Object.keys(nested).length === 0)
            delete next[category];
        else
            next[category] = nested;

        stored           = next;
        adapter.generals = deepCopy(next);
        generalsFile.writeAdapter();
    }

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

    function               deepCopy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? {}));
    }

    function               flatten(value: var, prefix: string): var {
        const flat = {};
        for (const key of Object.keys(value ?? {})) {
            const path = prefix === "" ? key : `${prefix}.${key}`;
            if (value[key] !== null && typeof value[key] === "object" && !Array.isArray(value[key]))
                Object.assign(flat, flatten(value[key], path));
            else
                flat[path] = value[key];
        }

        return flat;
    }

    function               isCategoryDirty(category: string): bool {
        return canonical(root.pending[category] ?? {}) !== root.canonical(root.flatten(root.stored[category] ?? {}, ""));
    }

    function               pendingValue(category: string, leafPath: string): var {
        return pending[category]?.[leafPath];
    }

    function               reloadHyprland(): void {
        HyprlandSetupServices.reloadHyprland();
    }

    function               resetFromDisk(): void {
        const fromDisk = adapter.generals ?? {};
        stored         = root.deepCopy(fromDisk);
        const seeded   = {};
        for (const category of Object.keys(stored))
            seeded[category] = flatten(root.stored[category], "");

        pending = seeded;
    }

    function               revertCategory(category: string): void {
        const next     = Object.assign({}, pending);
        next[category] = flatten(root.stored[category] ?? {}, "");
        pending        = next;
    }

    function               setPendingValue(category: string, leafPath: string, value: var): void {
        const next               = Object.assign({}, pending);
        next[category]           = Object.assign({}, next[category] ?? {});
        next[category][leafPath] = value;
        pending                  = next;
    }

    function               unflatten(flat: var): var {
        const nested = {};
        for (const path of Object.keys(flat ?? {})) {
            const segments = path.split(".");
            let cursor     = nested;
            for (let i = 0; i < segments.length - 1; i++) {
                if (cursor[segments[i]] === undefined || typeof cursor[segments[i]] !== "object")
                    cursor[segments[i]] = {};
                cursor = cursor[segments[i]];
            }

            cursor[segments[segments.length - 1]] = flat[path];
        }

        return nested;
    }

    FileView {
        id: generalsFile

        path: Paths.shellDir + "/generals.json"
        watchChanges: false
        onLoaded: root.resetFromDisk()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                ToastService.show(qsTr("Failed to read Hyprland settings: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaveFailed: err => {
            ToastService.show(qsTr("Failed to save Hyprland settings: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaved: root.reloadHyprland()

        JsonAdapter { // qmllint disable
            id: adapter

            property var generals: ({})
        }
    }
}
