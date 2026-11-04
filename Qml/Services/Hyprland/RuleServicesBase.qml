pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Services
import qs.Services.Hyprland

Singleton {
    id: root

    required property string filePath
    required property string loadFailedMessage
    required property string saveFailedMessage
    required property string savedMessage

    // rules and stored are ordered arrays: the order is the registration order
    // and the last matching rule wins, so reordering changes behavior.
    readonly property bool   dirty: root.canonical(root.rules) !== root.storedCanonical
    readonly property bool   loaded: rulesFile.loaded
    readonly property var    problems: {
        const map        = {};
        const nameCounts = {};
        for (const rule of root.rules) {
            const name = typeof rule.name === "string" ? rule.name : "";
            if (name !== "")
                nameCounts[name] = (nameCounts[name] ?? 0) + 1;
        }
        for (const rule of root.rules)
            map[rule.id] = root.ruleProblems(rule, nameCounts);
        return map;
    }
    readonly property string storedCanonical: root.canonical(root.stored)
    readonly property bool   valid: root.rules.every(rule => (root.problems[rule.id] ?? []).length === 0)

    property bool            initialLoadFinished: false
    property var             lastGoodRules: []
    property var             rules: []
    property var             stored: []

    function                 addRule(): void {
        const next = root.rules.slice();
        next.push(root.newRule());
        root.setRules(next);
    }

    function                 apply(): void {
        if (!root.initialLoadFinished || !root.valid)
            return;
        root.lastGoodRules = root.deepCopy(root.stored);
        root.stored        = root.deepCopy(root.rules);
        rulesFile.writeAdapter();
    }

    function                 canonical(value: var): string {
        if (value === null || value === undefined)
            return "null";
        if (Array.isArray(value))
            return `[${value.map(item => root.canonical(item)).join(",")}]`;
        if (typeof value === "object") {
            const keys = Object.keys(value).sort();
            return `{${keys.map(key => `${JSON.stringify(key)}:${root.canonical(value[key])}`).join(",")}}`;
        }
        return JSON.stringify(value);
    }

    function                 deepCopy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? []));
    }

    function                 deleteRule(id: string): void {
        root.setRules(root.rules.filter(rule => rule.id !== id));
    }

    function                 discardAll(): void {
        root.setRules(root.deepCopy(root.stored));
    }

    function                 duplicateRule(id: string): void {
        const index = root.ruleIndex(id);
        if (index < 0)
            return;
        const copy = root.deepCopy(root.rules[index]);
        copy.id    = root.newRuleId();
        // The source name would trip the duplicate-name check until renamed.
        copy.name  = "";
        const next = root.rules.slice();
        next.splice(index + 1, 0, copy);
        root.setRules(next);
    }

    function                 moveRule(id: string, delta: int): void {
        const from = root.ruleIndex(id);
        const to   = from + delta;
        if (from < 0 || to < 0 || to >= root.rules.length)
            return;
        const next  = root.rules.slice();
        const moved = next.splice(from, 1)[0];
        next.splice(to, 0, moved);
        root.setRules(next);
    }

    function                 newRule(): var {
        return {
            enabled: true,
            effects: {},
            id: root.newRuleId(),
            match: {},
            name: ""
        };
    }

    function                 newRuleId(): string {
        return `r-${Date.now().toString(36)}-${Math.floor(Math.random() * 1679616).toString(36)}`;
    }

    function                 refreshMatchPicks(): void {
    }

    function                 removeEffect(id: string, key: string): void {
        const rule = root.ruleById(id);
        if (!rule)
            return;
        const effects = Object.assign({}, rule.effects);
        delete effects[key];
        root.updateRule(id, {
            effects: effects
        });
    }

    function                 removeMatchProp(id: string, key: string): void {
        const rule = root.ruleById(id);
        if (!rule)
            return;
        const match = Object.assign({}, rule.match);
        delete match[key];
        root.updateRule(id, {
            match: match
        });
    }

    function                 resetFromDisk(): void {
        const loaded             = root.sanitizeLoadedRules(root.deepCopy(adapter.rules));
        root.initialLoadFinished = true;
        root.setRules(loaded);
        root.stored = root.deepCopy(loaded);
    }

    function                 ruleById(id: string): var {
        const snapshot = root.rules;
        return snapshot.find(rule => rule.id === id) ?? null;
    }

    function                 ruleIndex(id: string): int {
        const snapshot = root.rules;
        return snapshot.findIndex(rule => rule.id === id);
    }

    function                 ruleProblems(rule: var, nameCounts: var): var {
        return [];
    }

    function                 sanitizeLoadedRules(rawRules: var): var {
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

    function                 setEffect(id: string, key: string, value: var): void {
        const rule = root.ruleById(id);
        if (!rule)
            return;
        root.updateRule(id, {
            effects: Object.assign({}, rule.effects, {
                [key]: value
            })
        });
    }

    function                 setMatchProp(id: string, key: string, value: var): void {
        const rule = root.ruleById(id);
        if (!rule)
            return;
        root.updateRule(id, {
            match: Object.assign({}, rule.match, {
                [key]: value
            })
        });
    }

    function                 setRuleField(id: string, field: string, value: var): void {
        root.updateRule(id, {
            [field]: value
        });
    }

    // Nested arrays turn into non-Array wrappers across signal hops; the JSON
    // round trip restores plain arrays.
    function                 setRules(next: var): void {
        root.rules    = root.deepCopy(next);
        adapter.rules = root.deepCopy(next);
    }

    function                 updateRule(id: string, update: var): void {
        const index = root.ruleIndex(id);
        if (index < 0)
            return;
        const next  = root.rules.slice();
        next[index] = Object.assign({}, next[index], update);
        root.setRules(next);
    }

    function                 valueProblem(descriptor: var, value: var): string {
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

        path: root.filePath
        watchChanges: false
        atomicWrites: true
        onLoaded: root.resetFromDisk()
        onLoadFailed: errorCode => {
            if (errorCode === FileViewError.FileNotFound)
                root.initialLoadFinished = true;
            else
                ToastService.show(root.loadFailedMessage.arg(FileViewError.toString(errorCode)), qsTr("Hyprland"), "warning", 3000);
        }
        onSaveFailed: errorCode => ToastService.show(root.saveFailedMessage.arg(FileViewError.toString(errorCode)), qsTr("Hyprland"), "warning", 3000)
        onSaved: {
            HyprlandSetupServices.reloadHyprland();
            ToastService.show(root.savedMessage, qsTr("Hyprland"), "dialog-information", 3000);
        }

        JsonAdapter {
            id: adapter

            property var rules: []
        }
    }
}
