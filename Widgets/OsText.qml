import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Components

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    // color: Themes.colors.withAlpha(Themes.colors.background, 0.79)
    implicitWidth: container.width
    radius: 5

    Dots {
        id: container

        MaterialIcon {
            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            color: Themes.colors.tertiary
            font.family: Appearance.fonts.familyMono
            font.pointSize: Appearance.fonts.extraLarge * 0.8
            icon: "󱄅"
        }
    }
}
