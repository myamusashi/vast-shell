import QtQuick

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: root

    color: "transparent"
    implicitHeight: osIcon.contentHeight
    implicitWidth: osIcon.contentWidth
    radius: Appearance.rounding.small

    Icon {
        id: osIcon

        anchors.centerIn: parent
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.larger * 1.3
        icon: Distro.icon(SystemUsage.osId, SystemUsage.osIdLike)
        type: Icon.Nerd
    }

    MouseArea {
        anchors.fill: parent
        onClicked: GlobalStates.isSettingsOpen = true
    }

    Tooltip {
        anchorItem: root
        text: SystemUsage.osPrettyName ? qsTr("%1 · Settings").arg(SystemUsage.osPrettyName) : qsTr("Settings")
    }
}
