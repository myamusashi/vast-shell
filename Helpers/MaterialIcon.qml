import QtQuick

import qs.Data
import qs.Components

Text {
    id: root

    required property string icon

	font {
		family: Appearance.fonts.familyMaterial
		pointSize: Appearance.fonts.medium
		hintingPreference: Font.PreferNoHinting
		variableAxes: {
			"FILL": false,
			"wght": fontInfo.weight,
			"GRAD": -25,
			"opsz": 48
		}
	}


    antialiasing: true
    color: "transparent"
    renderType: Text.NativeRendering
    text: root.icon

    Behavior on color {
        CAnim {}
    }

    Behavior on opacity {
        NAnim {}
    }
}
