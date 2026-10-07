import QtQuick

import qs.Core.Utils

Text {
    id: root

    property alias icon: root.text
    property int   type: Icon.Material

    enum IconType {
        Material,
        Nerd,
        Weather
    }
    antialiasing: true
    color: "transparent"
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter

    font {
        family: root.type === Icon.Nerd ? Fonts.nerd : root.type === Icon.Weather ? "Weather Icons" : Fonts.material
        hintingPreference: Font.PreferFullHinting
        variableAxes: ({
                "opsz": 24,
                "wght": 400
            })
    }
}
