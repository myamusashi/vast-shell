pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components
import qs.Helpers
import qs.Services

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

		delegate: StyledRect {
			id: rectDelegate

			required property var modelData

			anchors.centerIn: parent
			color: Colours.m3Colors.m3Primary
			implicitWidth: 60
			implicitHeight: 60

			MaterialIcon {
				anchors.centerIn: parent
				icon: rectDelegate.modelData.icon
				color: Colours.m3Colors.m3OnPrimary
				width: 40
				height: 40
			}

			MArea {
				id: mArea

				anchors.fill: parent
				hoverEnabled: true
				onClicked: rectDelegate.modelData.action()
			}
		}
			//      delegate: StyledButton {
			//          id: buttonDelegate
			//
			//          required property var modelData
			//
			//          y: parent.height + 56
			//          anchors.horizontalCenter: parent.horizontalCenter
			// width: parent.width
			// showIconBackground: true
			//          height: 56
			//          buttonTitle: ""
			//          iconButton: modelData.icon
			//          iconSize: Appearance.fonts.size.extraLarge
			//          buttonColor: Colours.m3Colors.m3Primary
			//          buttonTextColor: Colours.m3Colors.m3OnPrimary
			//          buttonHeight: 56
			//          onClicked: modelData.action()
			//      }
    }
}
