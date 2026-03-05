import QtQuick

import qs.Configs

Text {
    id: root

    font {
        family: Appearance.fonts.family.sans
        pixelSize: Appearance.fonts.size.medium
        hintingPreference: Font.PreferFullHinting
        letterSpacing: 0
        variableAxes: {
            "opsz": root.fontInfo.pixelSize
        }
    }

    renderType: Text.NativeRendering
    renderTypeQuality: Text.VeryHighRenderTypeQuality
    antialiasing: true
    smooth: true
    color: "transparent"
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
}
