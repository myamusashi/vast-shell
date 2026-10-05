import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Clipboard configurations")

    SettingsCard {
        title: qsTr("General Settings")

        GridLayout {
            columns: 2

            SettingRow {
                description: qsTr("Turn on clipboard manager.")
                label: qsTr("Enable Clipboard:")

                StyledSwitch {
                    checked: Configs.clipboard.enabled

                    onCheckedChanged: Configs.clipboard.enabled = checked
                }
            }
            SettingRow {
                description: qsTr("Show thumbnail previews in the clipboard.")
                label: qsTr("Enable Previews:")

                StyledSwitch {
                    checked: Configs.clipboard.enablePreview

                    onCheckedChanged: Configs.clipboard.enablePreview = checked
                }
            }
            SettingRow {
                description: qsTr("Use Vim-style navigation inside the clipboard manager.")
                label: qsTr("Enable Vim Keybinds:")

                StyledSwitch {
                    checked: Configs.clipboard.enableVimKeybinds

                    onCheckedChanged: Configs.clipboard.enableVimKeybinds = checked
                }
            }
            SettingRow {
                description: qsTr("Keep the clipboard window open after copying an entry.")
                label: qsTr("Keep Clipboard Open After Copy:")

                StyledSwitch {
                    checked: Configs.clipboard.keepOpenAfterCopy

                    onCheckedChanged: Configs.clipboard.keepOpenAfterCopy = checked
                }
            }
        }
    }
    SettingsCard {
        title: qsTr("Preview Dimensions")
        visible: Configs.clipboard.enablePreview

        SettingRow {
            description: qsTr("Width of the clipboard preview in pixels.")
            label: qsTr("Preview Width:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 100
                stepSize: 10
                to: 1000
                value: Configs.clipboard.preview.sourceWidth

                onMoved: Configs.clipboard.preview.sourceWidth = value
            }
        }
        SettingRow {
            description: qsTr("Height of the clipboard preview in pixels.")
            label: qsTr("Preview Height:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 100
                stepSize: 10
                to: 1000
                value: Configs.clipboard.preview.sourceHeight

                onMoved: Configs.clipboard.preview.sourceHeight = value
            }
        }
    }
}
