import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

TextField {
    selectedTextColor: Colours.m3Colors.m3OnSecondaryContainer
    selectionColor: Colours.m3Colors.m3SecondaryContainer
    placeholderTextColor: Colours.m3Colors.m3Outline
    wrapMode: TextEdit.Wrap
    renderType: Text.QtRendering
    font {
        family: Appearance.fonts.family.sans
        pixelSize: Appearance.fonts.size.normal * 1.1
    }

    MArea {
        layerColor: "transparent"
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }

    background: StyledRect {
        color: Colours.m3Colors.m3Background
        radius: Appearance.rounding.small
        border {
            color: parent.focus ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.2)
            width: 2
        }

        Behavior on border.color {
            CAnim {}
        }
    }
}
