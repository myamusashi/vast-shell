import QtQuick

import qs.Core.Utils

Text {
    id: root

    enum IconType {
        Material,
        Nerd,
        Weather
    }

    property alias icon: root.text
    property int type: Icon.Material

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
