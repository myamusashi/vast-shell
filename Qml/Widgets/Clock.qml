import QtQuick

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

StyledRect {
    id: clock

    color: "transparent"
    implicitHeight: parent ? parent.height : 22
    implicitWidth: timeContainer.width + Appearance.padding.small
    radius: 6

    Dots {
        id: timeContainer

        spacing: 4

        Icon {
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.size.normal
            icon: "schedule"
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.size.small
            text: Qt.formatDateTime(Time?.date, "h:mm AP")
        }
    }

    MArea {
        anchors.fill: clock
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: GlobalStates.isDashboardOpen = !GlobalStates.isDashboardOpen
    }

    Tooltip {
        anchorItem: clock
        text: Time?.date ? Qt.formatDateTime(Time.date, "dddd, MMMM d, yyyy") : ""
    }
}
