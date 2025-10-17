import QtQuick
import QtQuick.Controls

import qs.Data
import qs.Helpers

Button {
	id: root

	required property string buttonTitle
	property string iconButton: ""
	property color buttonColor: Colors.colors.primary
	property color buttonHoverColor: Colors.withAlpha(Colors.colors.primary, 0.09)
	property color buttonPressedColor: Colors.withAlpha(Colors.colors.primary, 0.16)
	property color buttonTextColor: Colors.colors.on_primary
	property color buttonHoverTextColor: Colors.withAlpha(Colors.colors.on_primary, 0.86)
	property color buttonPressedTextColor: Colors.withAlpha(Colors.colors.on_primary, 0.95)
	property double fontSize: Appearance.fonts.medium

	hoverEnabled: true

	contentItem: Row {
		anchors.centerIn: parent

		MatIcon {
			icon: root.iconButton
			font.pixelSize: root.fontSize
			font.bold: true
			color: {
				if (root.hovered && root.pressed)
					root.buttonPressedTextColor;
				else if (root.hovered && !root.pressed)
					root.buttonHoverTextColor;
				else
					root.buttonTextColor;
			}
		}

		StyledText {
			text: root.buttonTitle
			font.pixelSize: root.fontSize
			font.bold: true
			color: {
				if (root.hovered && root.pressed)
					root.buttonPressedTextColor;
				else if (root.hovered && !root.pressed)
					root.buttonHoverTextColor;
				else
					root.buttonTextColor;
			}
		}
	}

	background: StyledRect {
		radius: Appearance.rounding.normal
		color: {
			if (root.hovered && root.pressed)
				root.buttonPressedColor;
			else if (root.hovered && !root.pressed)
				root.buttonHoverColor;
			else
				root.buttonColor;
		}
	}
}
