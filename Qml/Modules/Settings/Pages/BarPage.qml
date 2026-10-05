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
            description: qsTr("Keep the top bar visible.")
            label: qsTr("Always Open Bar:")

            StyledSwitch {
                checked: Configs.bar.alwaysOpenBar

                onCheckedChanged: Configs.bar.alwaysOpenBar = checked
            }
        }
        SettingRow {
            description: qsTr("Use a condensed layout.")
            label: qsTr("Compact Navigation Bar:")

            StyledSwitch {
                checked: Configs.bar.compact

                onCheckedChanged: Configs.bar.compact = checked
            }
        }
        SettingRow {
            description: qsTr("Height of the top bar in pixels.")
            label: qsTr("Bar Height:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 20
                stepSize: 1
                to: 100
                value: Configs.bar.barHeight

                onMoved: Configs.bar.barHeight = value
            }
        }
    }
    SettingsCard {
        title: qsTr("Workspace Display")

        SettingRow {
            description: qsTr("How many workspace indicators are shown on the bar.")
            label: qsTr("Number of Visible Workspaces:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 1
                showValuePopup: true
                snapEnabled: true
                stepSize: 1
                to: 15
                value: Configs.bar.visibleWorkspace

                onMoved: Configs.bar.visibleWorkspace = value
            }
        }
    }
}
