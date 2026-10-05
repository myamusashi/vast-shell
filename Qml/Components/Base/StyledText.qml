import QtQuick

import qs.Core.Utils

Text {
    id: root

    antialiasing: true
    color: "transparent"
    elide: Text.ElideRight
    renderType: Text.NativeRendering
    smooth: true
    verticalAlignment: Text.AlignVCenter

    Component.onCompleted: {
        font.variableAxes = {
            "wght": 650,
            "opsz": 24,
            "opsz": root.font.pixelSize
        };
    }

    font {
        family: Fonts.sans
        hintingPreference: Font.PreferFullHinting
        letterSpacing: 0
    }
}
