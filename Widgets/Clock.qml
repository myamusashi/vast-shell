import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: clock

    implicitWidth: timeContainer.width
    implicitHeight: parent.height
    color: "transparent"
    radius: Appearance.rounding.small

    Dots {
        id: timeContainer

        Icon {
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.size.large
            icon: "schedule"
        }

        StyledText {
            color: Colours.m3Colors.m3OnBackground
            font.bold: true
            font.pixelSize: Appearance.fonts.size.medium
            text: Qt.formatDateTime(Time?.date, "h:mm AP")
        }
    }

    MArea {
        anchors.fill: clock
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: GlobalStates.isCalendarOpen = !GlobalStates.isCalendarOpen
    }
}
