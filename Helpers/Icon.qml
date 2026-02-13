import QtQuick

import qs.Configs

Text {
    id: root

    enum IconType {
        Material,
        Weather
    }

    required property string icon
    readonly property var fontFamilies: [Appearance.fonts.family.material, "Weather Icons"]
    property int type: Icon.Material

    antialiasing: true
    color: "transparent"
    renderType: Text.NativeRendering
    text: root.icon

    font {
        family: root.type === Icon.Weather ? "Weather Icons" : Appearance.fonts.family.material
        pixelSize: Appearance.fonts.size.medium
        hintingPreference: Font.PreferNoHinting
    }
}
