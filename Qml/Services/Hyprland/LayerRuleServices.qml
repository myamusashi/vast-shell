pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell.Io

import qs.Core.Utils
import qs.Services.Hyprland

RuleServicesBase {
    id: root

    property var runningNamespaces: []

    function     matchPickValues(descriptor: var): var {
        if (!descriptor || descriptor.type !== "regex")
            return [];
        return namespaceQuickPicks();
    }

    function     namespaceQuickPicks(): var {
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

    function     newRule(): var {
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

    function     newRuleId(): string {
        return `l-${Date.now().toString(36)}-${Math.floor(Math.random() * 1679616).toString(36)}`;
    }

    function     parseLayers(text: string): void {
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

    function     refreshMatchPicks(): void {
        refreshRunningNamespaces();
    }

    function     refreshRunningNamespaces(): void {
        layersProbe.running = true;
    }

    function     ruleProblems(rule: var, nameCounts: var): var {
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

    filePath: Paths.shellDir + "/layerrules.json"
    loadFailedMessage: qsTr("Failed to read layer rules: %1")
    saveFailedMessage: qsTr("Failed to save layer rules: %1")
    savedMessage: qsTr("Layer rules saved")

    Process {
        id: layersProbe

        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersStdout
        }
        onExited: root.parseLayers(layersStdout.text)
    }
}
