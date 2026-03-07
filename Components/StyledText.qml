import QtQuick

import qs.Configs

Text {
    id: root

    font {
        family: Appearance.fonts.family.sans
        hintingPreference: Font.PreferFullHinting
        letterSpacing: 0
    }

    renderType: Text.NativeRendering
    antialiasing: true
    smooth: true
    color: "transparent"
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight

    Component.onCompleted: font.variableAxes = {
        "wght": 650,
        "opsz": 24,
        "opsz": root.font.pixelSize
    }
}
