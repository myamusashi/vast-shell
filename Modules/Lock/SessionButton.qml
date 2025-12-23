pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

ColumnLayout {
    Layout.alignment: Qt.AlignBottom
    spacing: 0.0

    Repeater {
        model: [
            {
                "icon": "power_settings_circle",
                "action": () => {
                    Quickshell.execDetached({
                        "command": ["sh", "-c", "systemctl poweroff"]
                    });
                }
            },
            {
                "icon": "restart_alt",
                "action": () => {
                    Quickshell.execDetached({
                        "command": ["sh", "-c", "systemctl reboot"]
                    });
                }
            },
            {
                "icon": "sleep",
                "action": () => {
                    Quickshell.execDetached({
                        "command": ["sh", "-c", "systemctl suspend"]
                    });
                }
            },
            {
                "icon": "door_open",
                "action": () => {
                    Quickshell.execDetached({
                        "command": ["sh", "-c", "hyprctl dispatch exit"]
                    });
                }
            }
        ]

        delegate: StyledButton {
            id: buttonDelegate

            required property var modelData

            implicitWidth: 50
            implicitHeight: 50

            iconBackgroundColor: "transparent"
            showIconBackground: true
            iconSize: Appearance.fonts.size.large
            iconButton: modelData.icon
            buttonTitle: ""
            onClicked: modelData.action()
        }
    }
}
