import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services

TextField {
    id: root

    property color backgroundColor: Colours.m3Colors.m3Background
    property real backgroundRadius: Appearance.rounding.small
    property color borderColor: focus ? Colours.m3Colors.m3Primary : Colours.withAlpha(Colours.m3Colors.m3Primary, 0.2)
    property real borderWidth: 0

    selectedTextColor: Colours.m3Colors.m3OnSecondaryContainer
    selectionColor: Colours.m3Colors.m3SecondaryContainer
    placeholderTextColor: Colours.m3Colors.m3Outline
    wrapMode: TextEdit.Wrap
    renderType: Text.QtRendering
    font {
        family: Appearance.fonts.family.sans
        pixelSize: Appearance.fonts.size.normal * 1.2
        weight: Font.DemiBold
    }

    MArea {
        layerColor: "transparent"
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }

    background: StyledRect {
        color: root.backgroundColor
        radius: root.backgroundRadius
        border {
            color: root.borderColor
            width: root.borderWidth
        }

        Behavior on border.color {
            CAnim {}
        }
    }
}
