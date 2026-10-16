import QtQuick

import qs.Core.Utils

Text {
    id: root

    readonly property bool   pending: IconFonts.isPending(root.setId)
    readonly property string setId: root.type === Icon.Phosphor ? "phosphor" : IconFonts.type

    property string          icon: ""
    property int             type: Icon.Material

    enum IconType {
        Material,
        Nerd,
        Weather,
        Phosphor
    }
    antialiasing: true
    color: "transparent"
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    text: root.pending ? "" : root.setId === "phosphor" ? IconMap.phosphorName(root.icon) : root.icon
    verticalAlignment: Text.AlignVCenter

    font {
        family: root.type === Icon.Nerd ? Fonts.nerd : root.type === Icon.Weather ? "Weather Icons" : IconFonts.familyFor(root.setId)
        hintingPreference: Font.PreferFullHinting
        variableAxes: ({
                "opsz": 24,
                "wght": 400
            })
    }
}
