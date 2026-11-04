pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.Core.Utils
import qs.Services
import qs.Services.Hyprland

RuleServicesBase {
    id: root

    readonly property var runningWindows: Hypr.toplevels?.values ?? []

    function              matchPickValues(descriptor: var): var {
        if (!descriptor || descriptor.type !== "regex")
            return [];
        return root.runningValues(descriptor.pickerField ?? "");
    }

    function              newRule(): var {
        return {
            enabled: true,
            effects: {},
            id: root.newRuleId(),
            match: {},
            name: ""
        };
    }

    function              newRuleId(): string {
        return `r-${Date.now().toString(36)}-${Math.floor(Math.random() * 1679616).toString(36)}`;
    }

    function              ruleProblems(rule: var, nameCounts: var): var {
        const found = [];
        const match = typeof rule.match === "object" && rule.match !== null ? rule.match : {};
        if (Object.keys(match).length === 0)
            found.push(qsTr("Add at least one match property."));

        const name = typeof rule.name === "string" ? rule.name : "";
        if (name !== "" && (nameCounts[name] ?? 0) > 1)
            found.push(qsTr("This name is used by more than one rule; Hyprland merges rules with the same name."));

        for (const key of Object.keys(match)) {
            const descriptor = WindowRuleSchema.matchPropByKey(key);
            if (!descriptor) {
                found.push(qsTr("Unknown match property: %1").arg(key));
                continue;
            }

            const problem = root.valueProblem(descriptor, match[key]);
            if (problem !== "")
                found.push(`${WindowRuleSchema.labelFromKey(key)}: ${problem}`);
        }

        const effects = typeof rule.effects === "object" && rule.effects !== null ? rule.effects : {};
        for (const key of Object.keys(effects)) {
            const descriptor = WindowRuleSchema.effectByKey(key);
            if (!descriptor) {
                found.push(qsTr("Unknown effect: %1").arg(key));
                continue;
            }
            const problem = root.valueProblem(descriptor, effects[key]);
            if (problem !== "")
                found.push(`${WindowRuleSchema.labelFromKey(key)}: ${problem}`);
        }

        return found;
    }

    function              runningValues(field: string): var {
        const values = [];
        const seen   = {};
        for (const toplevel of root.runningWindows) {
            const value = toplevel?.lastIpcObject?.[field];
            if (value === undefined || value === null)
                continue;

            const text = String(value);
            if (text === "" || seen[text])
                continue;
            seen[text] = true;
            values.push(text);
        }
        return values.sort();
    }

    filePath: Paths.shellDir + "/windowrules.json"
    loadFailedMessage: qsTr("Failed to read window rules: %1")
    saveFailedMessage: qsTr("Failed to save window rules: %1")
    savedMessage: qsTr("Window rules saved")
}
