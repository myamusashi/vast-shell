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

    readonly property bool dirty: canonical(rules) !== canonical(stored)
    readonly property bool loaded: rulesFile.loaded
    readonly property var  problems: {
        const map        = {};
        const nameCounts = {};
        for (const rule of rules) {
            const name = typeof rule.name === "string" ? rule.name : "";
            if (name !== "")
                nameCounts[name] = (nameCounts[name] ?? 0) + 1;
        }
        for (const rule of rules)
            map[rule.id] = ruleProblems(rule, nameCounts);
        return map;
    }
    readonly property bool valid: rules.every(rule => (problems[rule.id] ?? []).length === 0)

    property var           lastGoodRules: []
    property var           rules: []
    property var           runningNamespaces: []
    property var           stored: []

    function               addRule(): void {
        const next = rules.slice();
        next.push(newRule());
        setRules(next);
    }

    function               apply(): void {
        if (!valid)
            return;
        lastGoodRules = deepCopy(stored);
        stored        = deepCopy(rules);
        rulesFile.writeAdapter();
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
        return JSON.parse(JSON.stringify(value ?? []));
    }

    function               deleteRule(id: string): void {
        setRules(rules.filter(rule => rule.id !== id));
    }

    function               discardAll(): void {
        setRules(deepCopy(stored));
    }

    function               duplicateRule(id: string): void {
        const index = ruleIndex(id);
        if (index < 0)
            return;
        const copy = deepCopy(rules[index]);
        copy.id    = newRuleId();
        copy.name  = "";
        const next = rules.slice();
        next.splice(index + 1, 0, copy);
        setRules(next);
    }

    function               matchPickValues(descriptor: var): var {
        if (!descriptor || descriptor.type !== "regex")
            return [];
        return namespaceQuickPicks();
    }

    function               moveRule(id: string, delta: int): void {
        const from = ruleIndex(id);
        const to   = from + delta;
        if (from < 0 || to < 0 || to >= rules.length)
            return;
        const next  = rules.slice();
        const moved = next.splice(from, 1)[0];
        next.splice(to, 0, moved);
        setRules(next);
    }

    function               namespaceQuickPicks(): var {
        const values = [];
        const seen   = {};
        for (const namespace of LayerNamespaces.ownNamespaces.concat(runningNamespaces)) {
            if (seen[namespace])
                continue;
            seen[namespace] = true;
            values.push(namespace);
        }
        return values;
    }

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

    function               parseLayers(text: string): void {
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

    function               refreshMatchPicks(): void {
        refreshRunningNamespaces();
    }

    function               refreshRunningNamespaces(): void {
        layersProbe.running = true;
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

    function               resetFromDisk(): void {
        const loaded = sanitizeLoadedRules(adapter.rules);
        setRules(loaded);
        stored = deepCopy(loaded);
    }

    function               ruleById(id: string): var {
        const snapshot = rules;
        return snapshot.find(rule => rule.id === id) ?? null;
    }

    function               ruleIndex(id: string): int {
        const snapshot = rules;
        return snapshot.findIndex(rule => rule.id === id);
    }

    function               ruleProblems(rule: var, nameCounts: var): var {
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

    function               sanitizeLoadedRules(rawRules: var): var {
        if (!Array.isArray(rawRules))
            return [];
        const validRules = [];
        for (const entry of rawRules) {
            if (entry === null || typeof entry !== "object" || Array.isArray(entry) || typeof entry.id !== "string")
                continue;
            const rule = Object.assign({}, entry);
            if (rule.match === null || typeof rule.match !== "object" || Array.isArray(rule.match))
                rule.match = {};
            if (rule.effects === null || typeof rule.effects !== "object" || Array.isArray(rule.effects))
                rule.effects = {};
            validRules.push(rule);
        }
        return validRules;
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

    function               setRules(next: var): void {
        rules         = deepCopy(next);
        adapter.rules = deepCopy(next);
    }

    function               updateRule(id: string, update: var): void {
        const index = ruleIndex(id);
        if (index < 0)
            return;
        const next  = rules.slice();
        next[index] = Object.assign({}, next[index], update);
        setRules(next);
    }

    function               valueProblem(descriptor: var, value: var): string {
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

    FileView {
        id: rulesFile

        path: Paths.shellDir + "/layerrules.json"
        watchChanges: false
        atomicWrites: true
        onLoaded: root.resetFromDisk()
        onLoadFailed: err => {
            if (err !== FileViewError.FileNotFound)
                ToastService.show(qsTr("Failed to read layer rules: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaveFailed: err => ToastService.show(qsTr("Failed to save layer rules: %1").arg(FileViewError.toString(err)), qsTr("Hyprland"), "warning", 3000)
        onSaved: {
            HyprlandSetupServices.reloadHyprland();
            ToastService.show(qsTr("Layer rules saved"), qsTr("Hyprland"), "dialog-information", 3000);
        }

        JsonAdapter { // qmllint disable
            id: adapter

            property var rules: []
        }
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
