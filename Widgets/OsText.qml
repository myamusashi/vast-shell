import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    // color: Colours.colors.withAlpha(Colours.m3Colors.m3Background, 0.79)
    implicitWidth: container.width
    radius: 5

    Dots {
        id: container

        Icon {
            type: Icon.Material
            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            color: Colours.m3Colors.m3Primary
            font.family: Appearance.fonts.family.mono
            font.pixelSize: Appearance.fonts.size.extraLarge
            icon: "󱄅"
        }
    }
}
