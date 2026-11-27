pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Overview Configuration")

    SettingsCard {
        title: qsTr("Behavior & Appearance")

        SettingRow {
            description: qsTr("Enable the fullscreen workspace and window overview.")
            label: qsTr("Enable Workspace Overview:")

            StyledSwitch {
                checked: Configs.overview.enabled
                onCheckedChanged: {
                    Configs.overview.enabled = checked;
                    if (!checked && GlobalStates.isOverviewOpen)
                        GlobalStates.closePanel("overview");
                }
            }
        }

        SettingRow {
            description: qsTr("Automatically close the overview after creating and switching to a new workspace.")
            label: qsTr("Close on New Workspace:")

            StyledSwitch {
                checked: Configs.overview.closeOnNewWorkspace
                onCheckedChanged: Configs.overview.closeOnNewWorkspace = checked
            }
        }

        SettingRow {
            description: qsTr("Automatically move overview focus to match the currently active workspace.")
            label: qsTr("Follow Active Workspace:")

            StyledSwitch {
                checked: Configs.overview.followActiveWorkspace
                onCheckedChanged: Configs.overview.followActiveWorkspace = checked
            }
        }

        SettingRow {
            description: qsTr("Show empty workspaces in the range up to the highest active or occupied workspace.")
            label: qsTr("Show Empty Workspaces:")

            StyledSwitch {
                checked: Configs.overview.showEmptyWorkspaces
                onCheckedChanged: Configs.overview.showEmptyWorkspaces = checked
            }
        }

        SettingRow {
            description: qsTr("Stream live window contents in the preview grid instead of capturing a single frame.")
            label: qsTr("Live Window Previews:")

            StyledSwitch {
                checked: Configs.overview.live
                onCheckedChanged: Configs.overview.live = checked
            }
        }

        SettingRow {
            description: qsTr("Background dimming opacity for the overview backdrop and workspace strip (0.1 to 1.0).")
            label: qsTr("Background Dimming Alpha:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 0.1
                popupDecimals: 1
                stepSize: 0.1
                to: 1.0
                value: Configs.overview.alpha
                onMoved: Configs.overview.alpha = Math.round(value * 10) / 10
            }
        }
    }
}
