import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Data
import qs.Helpers

Button {
	id: root

	required property string buttonTitle
	property string iconButton: ""

	property color buttonColor: Themes.colors.primary
	property color buttonHoverColor: Themes.withAlpha(Themes.colors.primary, 0.08)
	property color buttonPressedColor: Themes.withAlpha(Themes.colors.primary, 0.12)
	property color buttonTextColor: Themes.colors.on_primary
	property color buttonHoverTextColor: Themes.withAlpha(Themes.colors.on_primary, 0.08)
	property color buttonPressedTextColor: Themes.withAlpha(Themes.colors.on_primary, 0.12)
	property color buttonBorderColor: Themes.colors.outline
	property int buttonBorderWidth: 2
	property int buttonHeight: 40
	property int iconTextSpacing: 8
	property bool isButtonFullRound: true
	property bool isButtonUseBorder: false
	property real backgroundRounding: 0

	implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
	implicitHeight: buttonHeight

	hoverEnabled: true

	contentItem: RowLayout {
		spacing: root.iconTextSpacing
		Layout.fillWidth: true
		Layout.alignment: Qt.AlignHCenter

		MatIcon {
			id: icon
			icon: root.iconButton
			font.pixelSize: Appearance.fonts.large * 1.2
			font.bold: true
			visible: root.iconButton !== ""
			color: {
				if (root.pressed)
					root.buttonPressedTextColor;
				else if (root.hovered)
					root.buttonHoverTextColor;
				else
					root.buttonTextColor;
			}
			Layout.alignment: Qt.AlignVCenter
		}

		StyledText {
			id: title
			text: root.buttonTitle
			font.pixelSize: Appearance.fonts.large
			font.weight: Font.Medium
			color: {
				if (root.pressed)
					root.buttonPressedTextColor;
				else if (root.hovered)
					root.buttonHoverTextColor;
				else
					root.buttonTextColor;
			}
			Layout.alignment: Qt.AlignVCenter
			Layout.preferredWidth: text === "" ? 0 : implicitWidth
			visible: text !== ""
		}
	}

	background: StyledRect {
		implicitWidth: root.implicitWidth
		implicitHeight: root.implicitHeight
		border {
			color: root.isButtonUseBorder ? root.buttonBorderColor : "transparent"
			width: root.isButtonUseBorder ? root.buttonBorderWidth : 0
		}
		radius: root.isButtonFullRound ? root.buttonHeight / 2 : root.backgroundRounding
		color: {
			if (root.pressed)
				root.buttonPressedColor;
			else if (root.hovered)
				root.buttonHoverColor;
			else
				root.buttonColor;
		}

		Behavior on color {
			ColAnim {
				duration: Appearance.animations.durations.small
				easing.type: Easing.OutCubic
			}
		}
	}

	Behavior on opacity {
		NumbAnim {
			duration: Appearance.animations.durations.small
			easing.type: Easing.OutCubic
		}
	}
}
