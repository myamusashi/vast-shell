import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    Layout.fillHeight: true
    color: "transparent"
    implicitWidth: childrenRect.width
    radius: 5

    Icon {
        Layout.alignment: Qt.AlignLeft | Qt.AlignHCenter
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.extraLarge
        icon: Distro.icon(SystemUsage.osId, SystemUsage.osIdLike)
        type: Icon.Nerd

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: GlobalStates.isSettingsOpen = true
        }
    }
}
