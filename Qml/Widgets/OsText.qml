import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    color: "transparent"
    implicitHeight: 22
    implicitWidth: osIcon.implicitWidth + Appearance.padding.small * 2
    radius: 6

    Icon {
        id: osIcon

        anchors.centerIn: parent
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.large
        icon: Distro.icon(SystemUsage.osId, SystemUsage.osIdLike)
        type: Icon.Nerd
    }

    MArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        layerRadius: 6
        onClicked: GlobalStates.isSettingsOpen = true
    }
}
