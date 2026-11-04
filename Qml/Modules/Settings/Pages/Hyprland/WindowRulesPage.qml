pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

SettingsPageBase {
    id: root

    readonly property var ruleIdSnapshot: WindowRuleServices.rules.map(rule => rule.id)

    property string       ruleIdCache: ""
    property var          ruleIds: []

    function              refreshRuleIds(): void {
        const joined = ruleIdSnapshot.join("\u0002");
        if (joined === ruleIdCache)
            return;
        ruleIdCache = joined;
        ruleIds     = ruleIdSnapshot.slice();
    }

    function              rulesLuaText(): string {
        if (HyprlandSetupServices.rulesLuaFileState === "exists" || HyprlandSetupServices.rulesLuaFileState === "created")
            return qsTr("vast_shell_rules.lua is set up.");
        if (HyprlandSetupServices.rulesLuaFileState === "missing" || HyprlandSetupServices.rulesLuaFileState === "creating")
            return qsTr("vast_shell_rules.lua will be created.");
        return "";
    }

    Component.onCompleted: refreshRuleIds()
    onRuleIdSnapshotChanged: refreshRuleIds()
    pageTitle: qsTr("Window Rules")

    HyprlandNoticeCard {
        icon: "warning"
        visible: !HyprlandSetupServices.onHyprland
        warning: true

        StyledText {
            color: Colours.m3Colors.m3OnErrorContainer
            text: qsTr("Hyprland with Lua configuration was not detected. Rules are saved, but only Hyprland applies them.")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
    }

    HyprlandNoticeCard {
        icon: "info"
        visible: HyprlandSetupServices.onHyprland

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                text: qsTr("Add at the bottom of hyprland.lua: %1").arg(HyprlandSetupServices.rulesRequireLine)
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: root.rulesLuaText()
                visible: text !== ""
                wrapMode: Text.Wrap
                Layout.maximumWidth: 260
            }

            ExtendedFloatingButton {
                icon.name: "content_copy"
                onClicked: HyprlandSetupServices.copyRulesRequireLine()
            }
        }
    }

    SettingsCard {
        title: qsTr("Rules")

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("Rules apply top to bottom and the last matching rule wins. A rule without any match property does nothing.")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("No window rules yet.")
            visible: root.ruleIds.length === 0
        }

        Repeater {
            model: root.ruleIds
            delegate: RuleCard {
                Layout.fillWidth: true
                ruleCount: root.ruleIds.length
                schema: WindowRuleSchema
                services: WindowRuleServices
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            ExtendedFloatingButton {
                icon.name: "add"
                text: qsTr("Add rule")
                onClicked: WindowRuleServices.addRule()
            }
        }
    }

    footer: [
        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3Error
            text: qsTr("Fix the marked rules to apply.")
            visible: WindowRuleServices.dirty && !WindowRuleServices.valid
        },
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            enabled: WindowRuleServices.dirty
            outlined: true
            text: qsTr("Revert")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: WindowRuleServices.discardAll()
        },
        ExtendedFloatingButton {
            enabled: WindowRuleServices.dirty && WindowRuleServices.valid
            text: qsTr("Apply")
            onClicked: WindowRuleServices.apply()
        }
    ]
}
