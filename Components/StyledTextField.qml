import QtQuick
import Qcm.Material as MD

import qs.Configs
import qs.Helpers
import qs.Services

MD.TextField {
    type: MD.Enum.TextFieldOutlined
    renderType: Text.QtRendering
    selectedTextColor: Colours.m3Colors.m3OnSecondaryContainer
    selectionColor: Colours.m3Colors.m3SecondaryContainer
    placeholderTextColor: Colours.m3Colors.m3Outline
    wrapMode: TextEdit.Wrap
    clip: false

    font {
        family: Appearance.fonts.family.sans
        pixelSize: Appearance.fonts.size.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: {
            "wght": 450,
            "wdth": 100
        }
    }

    MArea {
        layerColor: "transparent"
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }
}
