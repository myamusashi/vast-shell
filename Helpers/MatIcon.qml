import QtQuick

import qs.Data
import qs.Components

Text {
	id: root

	required property string icon
	property int grad: 0

	layer.enabled: true
	layer.samples: 0

	font.family: Appearance.fonts.family_Material
	font.pixelSize: Appearance.fonts.medium
	font.hintingPreference: Font.PreferNoHinting

	antialiasing: true

	verticalAlignment: Text.AlignVCenter
	horizontalAlignment: Text.AlignHCenter

	color: "transparent"

	renderType: Text.NativeRendering
	text: root.icon

	Behavior on color {
		ColAnim {}
	}

	Behavior on opacity {
		NumbAnim {}
	}
}
