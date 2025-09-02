import qs.Data
import QtQuick

Text {
	id: root

	property real targetFill: 0
	property real fill: 0
	property int grad: 0
	required property string icon

	font.family: Appearance.fonts.family_Material
	font.hintingPreference: Font.PreferFullHinting
	// layer.enabled: true


	font.variableAxes: {
		"FILL": Math.round(fill * 10) / 10,
		"opsz": root.fontInfo.pixelSize,
		"wght": root.fontInfo.weight
	}

	renderType: Text.NativeRendering
	text: root.icon

	Behavior on fill {
		NumberAnimation {
			duration: 50
			easing.type: Easing.InQuad
		}
	}
}
