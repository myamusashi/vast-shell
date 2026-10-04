import QtQuick
import QtQuick.Layouts
import qs.Components.Button

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Top Bar Configuration")

    SettingsCard {
        title: qsTr("Layout & Behavior")

        SettingRow {
            label: qsTr("Always Open Bar:")
            description: qsTr("Keep the top bar visible.")

            StyledSwitch {
                checked: Configs.bar.alwaysOpenBar
                onCheckedChanged: Configs.bar.alwaysOpenBar = checked
            }
        }

        SettingRow {
            label: qsTr("Compact Navigation Bar:")
            description: qsTr("Use a condensed layout.")

            StyledSwitch {
                checked: Configs.bar.compact
                onCheckedChanged: Configs.bar.compact = checked
            }
        }

        SettingRow {
            label: qsTr("Bar Height:")
            description: qsTr("Height of the top bar in pixels.")

            StyledSlide {
                from: 20
                to: 100
                stepSize: 1
                value: Configs.bar.barHeight
                onMoved: Configs.bar.barHeight = value
                Layout.preferredWidth: 200
            }
        }
    }

    SettingsCard {
        title: qsTr("Workspace Display")

        SettingRow {
            label: qsTr("Number of Visible Workspaces:")
            description: qsTr("How many workspace indicators are shown on the bar.")

            StyledSlide {
                from: 1
                to: 15
                stepSize: 1
                snapEnabled: true
                showValuePopup: true
                value: Configs.bar.visibleWorkspace
                onMoved: Configs.bar.visibleWorkspace = value
                Layout.preferredWidth: 200
            }
        }
    }
}
