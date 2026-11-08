pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
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
        },
        ExtendedFloatingButton {
            icon.name: "add"
            text: qsTr("Add rule")
            textColor: Colours.m3Colors.m3OnSecondaryContainer
            color: Colours.m3Colors.m3SecondaryContainer
            onClicked: WindowRuleServices.addRule()
        }
    ]
}
