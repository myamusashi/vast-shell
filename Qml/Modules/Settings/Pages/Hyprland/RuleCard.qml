pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Rectangle {
    id: root

    required property int    index
    required property string modelData

    readonly property var    allEffectSummaries: root.effectKeys.map(key => root.formatChipText(key, root.effects[key], root.schema.effectByKey(key)))
    readonly property var    allMatchSummaries: root.matchKeys.map(key => root.formatChipText(key, root.match[key], root.schema.matchPropByKey(key)))
    readonly property string customName: typeof root.rule?.name === "string" ? root.rule.name.trim() : ""
    readonly property var    effects: {
        if (root.rule !== null && typeof root.rule.effects === "object" && root.rule.effects !== null)
            return root.rule.effects;
        return ({});
    }
    readonly property string headlineText: {
        if (root.customName !== "")
            return root.customName;
        if (root.allMatchSummaries.length > 0)
            return root.allMatchSummaries[0];
        return qsTr("Untitled rule");
    }
    readonly property bool   invalid: root.ruleProblems.length > 0
    readonly property var    match: {
        if (root.rule !== null && typeof root.rule.match === "object" && root.rule.match !== null)
            return root.rule.match;
        return ({});
    }
    readonly property int    maxEffectChips: 4
    readonly property int    maxMatchChips: 3
    readonly property string overflowEffectTooltip: root.allEffectSummaries.slice(root.maxEffectChips).join("\n")
    readonly property string overflowMatchTooltip: root.allMatchSummaries.slice(root.maxMatchChips).join("\n")
    readonly property var    rule: root.services.ruleById(root.modelData)
    readonly property bool   ruleEnabled: root.rule?.enabled ?? true
    readonly property var    ruleProblems: root.services.problems[root.modelData] ?? []
    readonly property var    visibleEffectChips: root.allEffectSummaries.slice(0, root.maxEffectChips)
    readonly property var    visibleMatchChips: root.allMatchSummaries.slice(0, root.maxMatchChips)

    property string          effectKeyCache: ""
    property var             effectKeys: []
    property bool            expanded: false
    property string          matchKeyCache: ""
    property var             matchKeys: []
    property bool            reorderAllowed: true
    property int             ruleCount: 0
    property int             ruleOrderIndex: 0
    property var             schema
    property var             services

    signal                   deleted(string ruleId)
    signal                   duplicated(string newRuleId)
    signal                   expandToggled

    function                 formatChipText(key: string, value: var, descriptor: var): string {
        const label = root.schema.labelFromKey(key);
        if (descriptor && descriptor.type === "bool")
            return value === true ? label : `!${label}`;
        const formatted = root.formatValue(descriptor, value);
        return formatted !== "" ? `${label}: ${formatted}` : `${label}: ${qsTr("(empty)")}`;
    }

    function                 formatValue(descriptor: var, value: var): string {
        if (descriptor && descriptor.type === "exprVec2")
            return Array.isArray(value) ? `${value[0] ?? ""} × ${value[1] ?? ""}` : String(value ?? "");
        if (descriptor && descriptor.type === "enum") {
            if (value === "" || value === null || value === undefined)
                return qsTr("Default");
            const values = descriptor.values ?? [];
            const labels = descriptor.labels ?? [];
            const found  = values.indexOf(value);
            return found >= 0 && found < labels.length ? String(labels[found]) : String(value);
        }
        return value === null || value === undefined ? "" : String(value);
    }

    function                 refreshEffectKeys(): void {
        const keys   = Object.keys(root.effects);
        const joined = keys.join("\u0002");
        if (joined === root.effectKeyCache)
            return;
        root.effectKeyCache = joined;
        root.effectKeys     = keys;
    }

    function                 refreshMatchKeys(): void {
        const keys   = Object.keys(root.match);
        const joined = keys.join("\u0002");
        if (joined === root.matchKeyCache)
            return;
        root.matchKeyCache = joined;
        root.matchKeys     = keys;
    }

    Layout.fillWidth: true
    border.color: {
        if (root.invalid)
            return Colours.m3Colors.m3Error;
        if (root.expanded)
            return Colours.m3Colors.m3Primary;
        return Qt.alpha(Colours.m3Colors.m3OutlineVariant, 0.55);
    }
    border.width: root.invalid ? 2 : 1
    color: Colours.m3Colors.m3SurfaceContainer
    implicitHeight: cardLayout.implicitHeight + (Appearance.margin.normal * 2)
    radius: Appearance.rounding.normal
    Component.onCompleted: {
        root.refreshMatchKeys();
        root.refreshEffectKeys();
    }
    onEffectsChanged: root.refreshEffectKeys()
    onMatchChanged: root.refreshMatchKeys()

    ColumnLayout {
        id: cardLayout

        anchors {
            left: parent.left
            margins: Appearance.margin.normal
            right: parent.right
            top: parent.top
        }

        spacing: Appearance.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            RuleSummaryChip {
                Layout.alignment: Qt.AlignVCenter
                backgroundColor: Colours.m3Colors.m3SurfaceContainerHighest
                contentColor: Colours.m3Colors.m3OnSurfaceVariant
                maximumWidth: 64
                monospace: true
                text: `#${root.ruleOrderIndex + 1}`
                tooltipText: qsTr("Rule #%1 — rules apply top to bottom, last match wins").arg(root.ruleOrderIndex + 1)
            }

            StyledSwitch {
                id: ruleEnabledSwitch

                Layout.alignment: Qt.AlignVCenter
                checked: root.ruleEnabled
                onToggled: root.services.setRuleField(root.modelData, "enabled", checked)

                Tooltip {
                    anchorItem: ruleEnabledSwitch
                    text: root.ruleEnabled ? qsTr("Disable rule") : qsTr("Enable rule")
                }
            }

            Item {
                id: headerClickArea

                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                implicitHeight: Math.max(32, headerSummaryRow.implicitHeight)

                RowLayout {
                    id: headerSummaryRow

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    opacity: root.ruleEnabled ? 1.0 : 0.58
                    spacing: Appearance.spacing.small

                    StyledText {
                        readonly property bool untitled: root.customName === "" && root.allMatchSummaries.length === 0

                        Layout.fillWidth: true
                        color: untitled ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnSurface
                        elide: Text.ElideRight
                        font.italic: untitled
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        maximumLineCount: 1
                        text: root.headlineText
                    }

                    RuleSummaryChip {
                        Layout.alignment: Qt.AlignVCenter
                        backgroundColor: Colours.m3Colors.m3SurfaceContainerHighest
                        contentColor: Colours.m3Colors.m3OnSurfaceVariant
                        text: qsTr("Disabled")
                        visible: !root.ruleEnabled && !root.expanded
                    }

                    RuleSummaryChip {
                        Layout.alignment: Qt.AlignVCenter
                        backgroundColor: Colours.m3Colors.m3ErrorContainer
                        contentColor: Colours.m3Colors.m3OnErrorContainer
                        iconName: "error"
                        text: root.ruleProblems.length === 1 ? qsTr("1 issue") : qsTr("%1 issues").arg(root.ruleProblems.length)
                        tooltipText: root.ruleProblems.join("\n")
                        visible: root.invalid && !root.expanded
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.expandToggled()
                }
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                buttonEnabled: root.reorderAllowed && root.ruleOrderIndex > 0
                color: "transparent"
                disabledTooltipText: root.reorderAllowed ? qsTr("Already at top") : qsTr("Clear filter to reorder rules")
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "keyboard_arrow_up"
                size: "small"
                tooltipText: qsTr("Move rule up")
                onClicked: root.services.moveRule(root.modelData, -1)
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                buttonEnabled: root.reorderAllowed && root.ruleOrderIndex < root.ruleCount - 1
                color: "transparent"
                disabledTooltipText: root.reorderAllowed ? qsTr("Already at bottom") : qsTr("Clear filter to reorder rules")
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "keyboard_arrow_down"
                size: "small"
                tooltipText: qsTr("Move rule down")
                onClicked: root.services.moveRule(root.modelData, 1)
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                color: "transparent"
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: "content_copy"
                size: "small"
                tooltipText: qsTr("Duplicate rule")
                onClicked: {
                    const createdId = root.services.duplicateRule(root.modelData);
                    if (createdId !== "")
                        root.duplicated(createdId);
                }
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                color: "transparent"
                icon.color: Colours.m3Colors.m3Error
                icon.name: "delete"
                size: "small"
                tooltipText: qsTr("Delete rule")
                onClicked: {
                    root.deleted(root.modelData);
                    root.services.deleteRule(root.modelData);
                }
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                color: root.expanded ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                icon.color: root.expanded ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                icon.name: root.expanded ? "expand_less" : "expand_more"
                size: "small"
                tooltipText: root.expanded ? qsTr("Collapse rule") : qsTr("Expand rule")
                onClicked: root.expandToggled()
            }
        }

        Item {
            id: summaryChipStrip

            Layout.fillWidth: true
            implicitHeight: summaryFlow.implicitHeight
            visible: !root.expanded

            Flow {
                id: summaryFlow

                opacity: root.ruleEnabled ? 1.0 : 0.58
                spacing: Appearance.spacing.small
                width: parent.width

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3ErrorContainer
                    contentColor: Colours.m3Colors.m3OnErrorContainer
                    text: qsTr("No match properties")
                    visible: root.allMatchSummaries.length === 0
                }

                Repeater {
                    model: root.visibleMatchChips
                    delegate: RuleSummaryChip {
                        required property string modelData

                        backgroundColor: Colours.m3Colors.m3PrimaryContainer
                        contentColor: Colours.m3Colors.m3OnPrimaryContainer
                        text: modelData
                    }
                }

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3PrimaryContainer
                    contentColor: Colours.m3Colors.m3OnPrimaryContainer
                    monospace: true
                    text: `+${root.allMatchSummaries.length - root.maxMatchChips}`
                    tooltipText: root.overflowMatchTooltip
                    visible: root.allMatchSummaries.length > root.maxMatchChips
                }

                Item {
                    height: 24
                    width: arrowIcon.implicitWidth + 4

                    Icon {
                        id: arrowIcon

                        anchors.centerIn: parent
                        color: Colours.m3Colors.m3OnSurfaceVariant
                        font.pixelSize: Appearance.fonts.size.normal
                        icon: "arrow_forward"
                    }
                }

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3SurfaceContainerHighest
                    contentColor: Colours.m3Colors.m3OnSurfaceVariant
                    text: qsTr("No effects")
                    visible: root.allEffectSummaries.length === 0
                }

                Repeater {
                    model: root.visibleEffectChips
                    delegate: RuleSummaryChip {
                        required property string modelData

                        backgroundColor: Colours.m3Colors.m3SecondaryContainer
                        contentColor: Colours.m3Colors.m3OnSecondaryContainer
                        text: modelData
                    }
                }

                RuleSummaryChip {
                    backgroundColor: Colours.m3Colors.m3SecondaryContainer
                    contentColor: Colours.m3Colors.m3OnSecondaryContainer
                    monospace: true
                    text: `+${root.allEffectSummaries.length - root.maxEffectChips}`
                    tooltipText: root.overflowEffectTooltip
                    visible: root.allEffectSummaries.length > root.maxEffectChips
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.expandToggled()
            }
        }

        Loader {
            id: editorLoader

            Layout.fillWidth: true
            active: root.expanded
            visible: active
            sourceComponent: RuleCardEditor {
                effectKeys: root.effectKeys
                effects: root.effects
                invalid: root.invalid
                match: root.match
                matchKeys: root.matchKeys
                rule: root.rule
                ruleId: root.modelData
                ruleProblems: root.ruleProblems
                schema: root.schema
                services: root.services
            }
        }
    }
}
