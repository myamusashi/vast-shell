import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Components

TextField {
	id: passwordInput

	required property var polkitAgent

	Layout.fillWidth: true
	Layout.preferredHeight: 56

	font.family: Appearance.fonts.family_Sans
	font.pixelSize: Appearance.fonts.large * 1.2
	echoMode: polkitAgent?.flow?.responseVisible ? TextInput.Normal : TextInput.Password
	selectByMouse: true
	verticalAlignment: TextInput.AlignVCenter
	leftPadding: 16
	rightPadding: 16
	color: Colors.colors.on_surface

	placeholderText: "Enter password"
	placeholderTextColor: Colors.colors.on_surface_variant

	background: Rectangle {
		anchors.fill: parent
		color: "transparent"
		radius: Appearance.rounding.small

		border.color: {
			if (!passwordInput.enabled)
				return Colors.withAlpha(Colors.colors.outline, 0.38);
			else if (passwordInput.activeFocus)
				return Colors.colors.primary;
			else
				return Colors.colors.outline;
		}
		border.width: passwordInput.activeFocus ? 2 : 1

		Rectangle {
			anchors.fill: parent
			radius: parent.radius
			color: {
				if (!passwordInput.enabled)
					return "transparent";
				else if (passwordInput.activeFocus)
					return Colors.withAlpha(Colors.colors.primary, 0.08);
				else
					return "transparent";
			}

			Behavior on color {
				ColAnim {
					duration: Appearance.animations.durations.small
					easing.type: Easing.OutCubic
				}
			}
		}

		Behavior on border.color {
			ColAnim {
				duration: Appearance.animations.durations.small
				easing.type: Easing.OutCubic
			}
		}

		Behavior on border.width {
			PropertyAnimation {
				duration: Appearance.animations.durations.small
				easing.type: Easing.OutCubic
			}
		}
	}

	selectionColor: Colors.withAlpha(Colors.colors.primary, 0.24)
	selectedTextColor: Colors.colors.on_surface

	onAccepted: okButton.clicked()
}
