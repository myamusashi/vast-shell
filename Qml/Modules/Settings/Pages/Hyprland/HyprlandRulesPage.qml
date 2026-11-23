pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingsPageBase {
    id: root

    required property var  schema
    required property var  services

    readonly property bool allVisibleExpanded: root.visibleRuleIds.length > 0 && root.visibleRuleIds.every(ruleId => root.expandedRuleIds[ruleId] === true)
    readonly property bool filterActive: root.searchQuery.trim() !== "" || root.statusFilterIndex !== 0
    readonly property int  invalidRuleCount: root.services.rules.filter(rule => (root.services.problems[rule.id] ?? []).length > 0).length
    readonly property var  statusFilterModel: {
        if (root.invalidRuleCount > 0)
            return [qsTr("All"), qsTr("Enabled"), qsTr("Disabled"), qsTr("Issues (%1)").arg(root.invalidRuleCount)];
        return [qsTr("All"), qsTr("Enabled"), qsTr("Disabled")];
    }
    readonly property int  totalRuleCount: root.services.rules.length
    readonly property var  visibleRuleIdSnapshot: root.services.rules.filter(rule => root.ruleMatchesFilter(rule)).map(rule => rule.id)

    property string        emptyText: ""
    property var           expandedRuleIds: ({})
    property string        overviewText: ""
    property string        searchPlaceholder: qsTr("Filter rules by name, match, or effect...")
    property string        searchQuery: ""
    property int           statusFilterIndex: 0
    property string        visibleRuleIdCache: ""
    property var           visibleRuleIds: []

    function               clearFilters(): void {
        searchField.text       = "";
        root.searchQuery       = "";
        root.statusFilterIndex = 0;
    }

    function               pruneExpandedIds(): void {
        const existing = {};
        for (const rule of root.services.rules)
            existing[rule.id] = true;

        const next = {};
        for (const ruleId of Object.keys(root.expandedRuleIds)) {
            if (existing[ruleId] && root.expandedRuleIds[ruleId] === true)
                next[ruleId] = true;
        }
        root.expandedRuleIds = next;
    }

    function               refreshVisibleRuleIds(): void {
        const joined = root.visibleRuleIdSnapshot.join("\u0002");
        if (joined === root.visibleRuleIdCache)
            return;
        root.visibleRuleIdCache = joined;
        root.visibleRuleIds     = root.visibleRuleIdSnapshot.slice();
    }

    function               revealRuleById(ruleId: string): void {
        root.refreshVisibleRuleIds();
        const visibleIndex = root.visibleRuleIds.indexOf(ruleId);
        if (visibleIndex >= 0)
            root.revealItem(ruleRepeater, visibleIndex);
    }

    function               ruleMatchesFilter(rule: var): bool {
        if (!rule)
            return false;
        if (root.statusFilterIndex === 1 && rule.enabled === false)
            return false;
        if (root.statusFilterIndex === 2 && rule.enabled !== false)
            return false;
        if (root.statusFilterIndex === 3 && (root.services.problems[rule.id] ?? []).length === 0)
            return false;

        const query = root.searchQuery.trim().toLowerCase();
        if (query === "")
            return true;

        if (String(rule.name ?? "").toLowerCase().includes(query))
            return true;

        const match = typeof rule.match === "object" && rule.match !== null ? rule.match : ({});
        for (const key of Object.keys(match)) {
            const label = root.schema.labelFromKey(key).toLowerCase();
            if (key.toLowerCase().includes(query) || label.includes(query) || String(match[key] ?? "").toLowerCase().includes(query))
                return true;
        }

        const effects = typeof rule.effects === "object" && rule.effects !== null ? rule.effects : ({});
        for (const key of Object.keys(effects)) {
            const label = root.schema.labelFromKey(key).toLowerCase();
            if (key.toLowerCase().includes(query) || label.includes(query) || String(effects[key] ?? "").toLowerCase().includes(query))
                return true;
        }

        return false;
    }

    function               setRuleExpanded(ruleId: string, expanded: bool): void {
        const next = Object.assign({}, root.expandedRuleIds);
        if (expanded)
            next[ruleId] = true;
        else
            delete next[ruleId];
        root.expandedRuleIds = next;
    }

    function               toggleExpandAll(): void {
        const next   = Object.assign({}, root.expandedRuleIds);
        const expand = !root.allVisibleExpanded;
        for (const ruleId of root.visibleRuleIds) {
            if (expand)
                next[ruleId] = true;
            else
                delete next[ruleId];
        }
        root.expandedRuleIds = next;
    }

    function               toggleRuleExpanded(ruleId: string): void {
        root.setRuleExpanded(ruleId, root.expandedRuleIds[ruleId] !== true);
    }

    Component.onCompleted: root.refreshVisibleRuleIds()
    onInvalidRuleCountChanged: {
        if (root.statusFilterIndex === 3 && root.invalidRuleCount === 0)
            root.statusFilterIndex = 0;
    }
    onVisibleRuleIdSnapshotChanged: root.refreshVisibleRuleIds()

    HyprlandNoticeCard {
        icon: "warning"
        visible: !HyprlandSetupServices.onHyprland
        warning: true

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnErrorContainer
            text: qsTr("Hyprland with Lua configuration was not detected. Rules are saved, but only Hyprland applies them.")
            wrapMode: Text.Wrap
        }
    }

    SettingsCard {
        title: qsTr("Rules")

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: root.overviewText
                wrapMode: Text.Wrap
            }

            RuleSummaryChip {
                Layout.alignment: Qt.AlignTop
                backgroundColor: Colours.m3Colors.m3SurfaceContainerHigh
                contentColor: Colours.m3Colors.m3OnSurfaceVariant
                monospace: true
                text: {
                    if (root.filterActive)
                        return qsTr("%1 / %2").arg(root.visibleRuleIds.length).arg(root.totalRuleCount);
                    if (root.totalRuleCount === 1)
                        return qsTr("1 rule");
                    return qsTr("%1 rules").arg(root.totalRuleCount);
                }
                visible: root.totalRuleCount > 0
            }

            RuleSummaryChip {
                Layout.alignment: Qt.AlignTop
                backgroundColor: Colours.m3Colors.m3ErrorContainer
                contentColor: Colours.m3Colors.m3OnErrorContainer
                iconName: "error"
                text: root.invalidRuleCount === 1 ? qsTr("1 invalid") : qsTr("%1 invalid").arg(root.invalidRuleCount)
                visible: root.invalidRuleCount > 0
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small
            visible: root.totalRuleCount > 0

            MaterialTextField {
                id: searchField

                Layout.fillWidth: true
                compact: true
                leadingIcon.name: "search"
                placeholderText: root.searchPlaceholder
                trailingIcon.name: text !== "" ? "close" : ""
                onTextChanged: root.searchQuery = text
                onTrailingIconClicked: {
                    text             = "";
                    root.searchQuery = "";
                }
            }

            ConnectedButtonGroup {
                Layout.alignment: Qt.AlignVCenter
                currentIndex: root.statusFilterIndex
                model: root.statusFilterModel
                onClicked: index => root.statusFilterIndex = index
            }

            FloatingButton {
                Layout.alignment: Qt.AlignVCenter
                buttonEnabled: root.visibleRuleIds.length > 0
                color: Colours.m3Colors.m3SurfaceContainerHigh
                icon.color: Colours.m3Colors.m3OnSurfaceVariant
                icon.name: root.allVisibleExpanded ? "expand_less" : "expand_more"
                size: "small"
                tooltipText: root.allVisibleExpanded ? qsTr("Collapse all shown rules") : qsTr("Expand all shown rules")
                onClicked: root.toggleExpandAll()
            }
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: root.emptyText
            visible: root.totalRuleCount === 0
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal
            visible: root.totalRuleCount > 0 && root.visibleRuleIds.length === 0

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: qsTr("No rules match the current filter.")
                wrapMode: Text.Wrap
            }

            ExtendedFloatingButton {
                outlined: true
                text: qsTr("Clear filter")
                textColor: Colours.m3Colors.m3OnSurface
                onClicked: root.clearFilters()
            }
        }

        Repeater {
            id: ruleRepeater

            model: root.visibleRuleIds
            delegate: RuleCard {
                id: ruleDelegate

                Layout.fillWidth: true
                expanded: root.expandedRuleIds[ruleDelegate.modelData] === true
                reorderAllowed: !root.filterActive
                ruleCount: root.totalRuleCount
                ruleOrderIndex: root.services.ruleIndex(ruleDelegate.modelData)
                schema: root.schema
                services: root.services
                onDeleted: ruleId => root.setRuleExpanded(ruleId, false)
                onDuplicated: newRuleId => {
                    root.setRuleExpanded(newRuleId, true);
                    root.revealRuleById(newRuleId);
                }
                onExpandToggled: root.toggleRuleExpanded(ruleDelegate.modelData)
            }
        }
    }

    footer: [
        FloatingButton {
            buttonEnabled: root.canScroll && !root.atTop
            color: Colours.m3Colors.m3SurfaceContainerHigh
            disabledTooltipText: qsTr("Already at top")
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "vertical_align_top"
            size: "small"
            tooltipPosition: Edges.Top
            tooltipText: qsTr("Scroll to top")
            onClicked: root.scrollToTop()
        },
        FloatingButton {
            buttonEnabled: root.canScroll && !root.atBottom
            color: Colours.m3Colors.m3SurfaceContainerHigh
            disabledTooltipText: qsTr("Already at bottom")
            icon.color: Colours.m3Colors.m3OnSurfaceVariant
            icon.name: "vertical_align_bottom"
            size: "small"
            tooltipPosition: Edges.Top
            tooltipText: qsTr("Scroll to bottom")
            onClicked: root.scrollToBottom()
        },
        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            elide: Text.ElideRight
            text: qsTr("Fix the marked rules to apply.")
            visible: root.services.dirty && !root.services.valid
        },
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            enabled: root.services.dirty
            outlined: true
            text: qsTr("Revert")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: {
                root.services.discardAll();
                root.pruneExpandedIds();
            }
        },
        ExtendedFloatingButton {
            enabled: root.services.dirty && root.services.valid
            text: qsTr("Apply")
            onClicked: root.services.apply()
        },
        ExtendedFloatingButton {
            color: Colours.m3Colors.m3SecondaryContainer
            icon.name: "add"
            text: qsTr("Add rule")
            textColor: Colours.m3Colors.m3OnSecondaryContainer
            onClicked: {
                if (root.filterActive)
                    root.clearFilters();
                const createdId = root.services.addRule();
                root.setRuleExpanded(createdId, true);
                root.revealRuleById(createdId);
            }
        }
    ]
}
