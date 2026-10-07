import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Services

WrapperRectangle {
    id: root

    // Expose clockLayout so parent can animate its opacity
    property alias clockLayout: clockLayout
    property var   currentDate: new Date()

    function       getDayName(index) {
        const days = [qsTr("Sunday"), qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thuesday"), qsTr("Friday"), qsTr("Saturday")];
        return days[index];
    }
    function       getMonthName(index) {
        const months = [qsTr("Jan"), qsTr("Feb"), qsTr("Mar"), qsTr("Apr"), qsTr("Mei"), qsTr("Jun"), qsTr("Jul"), qsTr("Aug"), qsTr("Sep"), qsTr("Okt"), qsTr("Nov"), qsTr("Des")];
        return months[index];
    }

    color: "transparent"

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentDate = new Date()
    }

    RowLayout {
        id: clockLayout

        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            text: qsTr("%1 %2").arg(root.currentDate.getDate()).arg(root.getMonthName(root.currentDate.getMonth()))
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            text: {
                const hours   = root.currentDate.getHours().toString().padStart(2, '0');
                const minutes = root.currentDate.getMinutes().toString().padStart(2, '0');
                return `${hours}:${minutes}`;
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            text: root.getDayName(root.currentDate.getDay())
        }
    }
}
