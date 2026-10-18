import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Dock Configuration")

    SettingsCard {
        title: qsTr("Layout & Behavior")

        SettingRow {
            description: qsTr("Show the dock at the bottom center of the focused monitor. Pinned applications sit on the left, the active workspace windows in the middle, and the launcher toggle on the right. Pin or unpin applications from the launcher with the pin button on each row, or right click a pinned dock icon.")
            label: qsTr("Enable Dock:")

            StyledSwitch {
                checked: Configs.dock.enabled
                onCheckedChanged: Configs.dock.enabled = checked
            }
        }

        SettingRow {
            description: qsTr("Height of the dock in pixels.")
            label: qsTr("Dock Height:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 48
                stepSize: 1
                to: 100
                value: Configs.dock.dockHeight
                onMoved: Configs.dock.dockHeight = value
            }
        }

        SettingRow {
            description: qsTr("Size of every dock icon slot in pixels.")
            label: qsTr("Icon Size:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 28
                stepSize: 1
                to: 64
                value: Configs.dock.iconSlot
                onMoved: Configs.dock.iconSlot = value
            }
        }
    }
}
