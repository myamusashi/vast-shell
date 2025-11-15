import QtQuick
import qs.Data

Text {
    id: root

    font.family: Appearance.fonts.family_Sans
    font.pixelSize: Appearance.fonts.medium
    font.hintingPreference: Font.PreferVerticalHinting
    font.letterSpacing: -0.2
    renderType: Text.NativeRendering

    color: "transparent"
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight

    Behavior on color {
        ColAnim {}
    }
}
