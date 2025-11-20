import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Controls
import Quickshell

import qs.Configs
import qs.Helpers

TextField {
    id: root

    Material.theme: Material.System
    Material.accent: Themes.m3Colors.primary
    Material.primary: Themes.m3Colors.primary
    Material.background: Themes.m3Colors.surface
    Material.foreground: Themes.m3Colors.onSurface
    Material.containerStyle: Material.Outlined
    renderType: Text.QtRendering

    selectedTextColor: Themes.m3Colors.onSecondaryContainer
    selectionColor: Themes.m3Colors.secondaryContainer
    placeholderTextColor: Themes.m3Colors.outline
    clip: true

    font {
        family: Appearance.fonts.familySans
        pixelSize: Appearance.fonts.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: {
            "wght": 450,
            "wdth": 100
        }
    }
    wrapMode: TextEdit.Wrap

    MArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
