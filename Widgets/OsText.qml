import QtQuick
import QtQuick.Layouts

import qs.Data
import qs.Helpers
import qs.Components

StyledRect {
	Layout.fillHeight: true
	color: "transparent"
	// color: Themes.colors.withAlpha(Themes.colors.background, 0.79)
	implicitWidth: container.width
	radius: 5

	Dots {
		id: container

		MatIcon {
			Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
			color: Themes.colors.tertiary
			font.family: Appearance.fonts.family_Mono
			font.pixelSize: Appearance.fonts.large * 1.7
			icon: "󱄅"
		}
	}
}
