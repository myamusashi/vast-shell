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

    // stored mirrors layerrules.json; pending holds the working draft.
    // Both are ordered arrays: the order is the registration order and the
    // last matching rule wins, so reordering changes behavior.
    readonly property bool dirty: canonical(pending) !== canonical(stored)
    readonly property bool loaded: rulesFile.loaded

    // Namespaces of layers vast-shell itself creates, offered as quick picks.
    readonly property var  ownNamespaces: ["shell:drawers", "shell:wallpaper", "shell:dynamicIsland", "shell:screenshot-overlay"]
    readonly property var  problems: {
        const map        = {};
        const nameCounts = {};
        for (const rule of pending) {
            const name = typeof rule.name === "string" ? rule.name : "";
            if (name !== "")
                nameCounts[name] = (nameCounts[name] ?? 0) + 1;
        }
        for (const rule of pending)
            map[rule.id] = ruleProblems(rule, nameCounts);
        return map;
    }
    readonly property bool valid: pending.every(rule => (problems[rule.id] ?? []).length === 0)

    property var           pending: []
    property var           runningNamespaces: []
    property var           stored: []

    function               addRule(): void {
        const next = pending.slice();
        next.push(newRule());
        pending = next;
    }

    FileView {
        id: rulesFile

        path: Paths.shellDir + "/layerrules.json"
        watchChanges: false
        onLoaded: root.resetFromDisk()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                ToastService.show(qsTr("Failed to read layer rules: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaveFailed: err => ToastService.show(qsTr("Failed to save layer rules: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000)
        onSaved: HyprlandSetupServices.reloadHyprland()

        JsonAdapter { // qmllint disable
            id: adapter

            property var rules: []
        }
    }

    // Writes the whole draft into layerrules.json, then reloads Hyprland (onSaved).

    function               apply(): void {
        stored        = deepCopy(pending);
        adapter.rules = deepCopy(stored);
        rulesFile.writeAdapter();
    }

    // Stable string form (sorted keys) so drafts and parsed files compare
    // order-independently; array order is kept because it is meaningful.

    function               canonical(value: var): string { // qmllint disable
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
        return JSON.parse(JSON.stringify(value ?? []));
    }

    function               deleteRule(id: string): void {
        pending = pending.filter(rule => rule.id !== id);
    }

    function               discardAll(): void {
        pending = deepCopy(stored);
    }

    function               duplicateRule(id: string): void {
        const index = ruleIndex(id);
        if (index < 0)
            return;
        const copy = deepCopy(pending[index]);
        copy.id    = newRuleId();
        // The source name would trip the duplicate-name check until renamed.
        copy.name  = "";
        const next = pending.slice();
        next.splice(index + 1, 0, copy);
        pending = next;
    }

    function               moveRule(id: string, delta: int): void {
        const from = ruleIndex(id);
        const to   = from + delta;
        if (from < 0 || to < 0 || to >= pending.length)
            return;
        const next  = pending.slice();
        const moved = next.splice(from, 1)[0];
        next.splice(to, 0, moved);
        pending = next;
    }

    // New layer rules start with the namespace row because it is the only
    // supported match property.

    function               newRule(): var {
        return {
            enabled: true,
            effects: {},
            id: newRuleId(),
            match: {
                namespace: ""
            },
            name: ""
        };
    }

    function               newRuleId(): string {
        return `l-${Date.now().toString(36)}-${Math.floor(Math.random() * 1679616).toString(36)}`;
    }

    // Pick-from-running values for a match property (regex props only).

    function               matchPickValues(descriptor: var): var { // qmllint disable
        if (!descriptor || descriptor.type !== "regex")
            return [];
        return namespaceQuickPicks();
    }

    function               refreshMatchPicks(): void {
        refreshRunningNamespaces();
    }

    // Quick picks for the namespace field: vast-shell's own namespaces first,
    // then everything currently running.

    function               namespaceQuickPicks(): var {
        const values = [];
        const seen   = {};
        for (const namespace of ownNamespaces.concat(runningNamespaces)) {
            if (seen[namespace])
                continue;
            seen[namespace] = true;
            values.push(namespace);
        }
        return values;
    }

    function               removeEffect(id: string, key: string): void {
        const rule = ruleById(id);
        if (!rule)
            return;
        const effects = Object.assign({}, rule.effects);
        delete effects[key];
        updateRule(id, {
            effects: effects
        });
    }

    function               removeMatchProp(id: string, key: string): void {
        const rule = ruleById(id);
        if (!rule)
            return;
        const match = Object.assign({}, rule.match);
        delete match[key];
        updateRule(id, {
            match: match
        });
    }

    // Read-only query of the running layer surface namespaces; a fresh sample
    // is taken whenever the picker opens.

    function               refreshRunningNamespaces(): void {
        layersProbe.running = true;
    }

    function               resetFromDisk(): void {
        stored  = deepCopy(adapter.rules ?? []);
        pending = deepCopy(stored);
    }

    function               ruleById(id: string): var { // qmllint disable
        return pending.find(rule => rule.id === id) ?? null;
    }

    function               ruleIndex(id: string): int { // qmllint disable
        return pending.findIndex(rule => rule.id === id);
    }

    function               ruleProblems(rule: var, nameCounts: var): var { // qmllint disable
        const found = [];
        const match = typeof rule.match === "object" && rule.match !== null ? rule.match : {};
        if (Object.keys(match).length === 0)
            found.push(qsTr("Add at least one match property."));
        const name = typeof rule.name === "string" ? rule.name : "";
        if (name !== "" && (nameCounts[name] ?? 0) > 1)
            found.push(qsTr("This name is used by more than one rule; Hyprland merges rules with the same name."));
        for (const key of Object.keys(match)) {
            const descriptor = LayerRuleSchema.matchPropByKey(key);
            if (!descriptor) {
                found.push(qsTr("Unknown match property: %1").arg(key));
                continue;
            }
            const problem = valueProblem(descriptor, match[key]);
            if (problem !== "")
                found.push(`${LayerRuleSchema.labelFromKey(key)}: ${problem}`);
        }
        const effects = typeof rule.effects === "object" && rule.effects !== null ? rule.effects : {};
        for (const key of Object.keys(effects)) {
            const descriptor = LayerRuleSchema.effectByKey(key);
            if (!descriptor) {
                found.push(qsTr("Unknown effect: %1").arg(key));
                continue;
            }
            const problem = valueProblem(descriptor, effects[key]);
            if (problem !== "")
                found.push(`${LayerRuleSchema.labelFromKey(key)}: ${problem}`);
        }
        return found;
    }

    function               setEffect(id: string, key: string, value: var): void {
        const rule = ruleById(id);
        if (!rule)
            return;
        updateRule(id, {
            effects: Object.assign({}, rule.effects, {
                [key]: value
            })
        });
    }

    function               setMatchProp(id: string, key: string, value: var): void {
        const rule = ruleById(id);
        if (!rule)
            return;
        updateRule(id, {
            match: Object.assign({}, rule.match, {
                [key]: value
            })
        });
    }

    function               setRuleField(id: string, field: string, value: var): void {
        updateRule(id, {
            [field]: value
        });
    }

    function               updateRule(id: string, update: var): void { // qmllint disable
        const index = ruleIndex(id);
        if (index < 0)
            return;
        const next  = pending.slice();
        next[index] = Object.assign({}, next[index], update);
        pending     = next;
    }

    function               valueProblem(descriptor: var, value: var): string { // qmllint disable
        if (descriptor.type === "int" || descriptor.type === "float") {
            if (typeof value !== "number" || isNaN(value))
                return qsTr("Must be a number.");
            if (descriptor.min !== undefined && value < descriptor.min)
                return qsTr("Must be at least %1.").arg(descriptor.min);
            if (descriptor.max !== undefined && value > descriptor.max)
                return qsTr("Must be at most %1.").arg(descriptor.max);
            return "";
        }
        if (descriptor.type === "exprVec2") {
            if (!Array.isArray(value) || value.length !== 2)
                return qsTr("Must be two values.");
            if (String(value[0] ?? "").trim() === "" || String(value[1] ?? "").trim() === "")
                return qsTr("Both values are required.");
            return "";
        }
        if (descriptor.type === "enum" && !(descriptor.values ?? []).includes(value))
            return qsTr("Must be one of: %1.").arg((descriptor.values ?? []).join(", "));
        return "";
    }

    // hyprctl layers -j nests layers per monitor under "levels"; only the
    // namespace is needed here.

    function               parseLayers(text: string): void { // qmllint disable
        let data = null;
        try {
            data = JSON.parse(text);
        } catch (error) {
            data = null;
        }
        if (!data || typeof data !== "object")
            return;
        const found = {};
        for (const monitor of Object.values(data)) {
            const levels = monitor?.levels ?? {};
            for (const layers of Object.values(levels)) {
                if (!Array.isArray(layers))
                    continue;
                for (const layer of layers) {
                    const namespace = String(layer?.namespace ?? "");
                    if (namespace !== "")
                        found[namespace] = true;
                }
            }
        }
        runningNamespaces = Object.keys(found).sort();
    }

    Process {
        id: layersProbe

        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersStdout
        }
        onExited: root.parseLayers(layersStdout.text)
    }
}
