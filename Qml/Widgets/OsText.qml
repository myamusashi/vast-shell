import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    implicitWidth: container.width
    radius: 5

    Dots {
        id: container

        Icon {
            type: Icon.Nerd
            Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge
            icon: Distro.icon(SystemUsage.osId, SystemUsage.osIdLike)
        }
    }
}
