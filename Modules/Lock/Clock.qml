import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Services

WrapperRectangle {
    id: root

    color: "transparent"

    // Expose clockLayout so parent can animate its opacity
    property alias clockLayout: clockLayout
    property var currentDate: new Date()

    function getDayName(index) {
        const days = [qsTr("Sunday"), qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thuesday"), qsTr("Friday"), qsTr("Saturday")];
        return days[index];
    }

    function getMonthName(index) {
        const months = [qsTr("Jan"), qsTr("Feb"), qsTr("Mar"), qsTr("Apr"), qsTr("Mei"), qsTr("Jun"), qsTr("Jul"), qsTr("Aug"), qsTr("Sep"), qsTr("Okt"), qsTr("Nov"), qsTr("Des")];
        return months[index];
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.currentDate = new Date()
    }

    ColumnLayout {
        id: clockLayout

        opacity: 0

        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            renderType: Text.NativeRendering
            text: {
                const hours = root.currentDate.getHours().toString().padStart(2, '0');
                const minutes = root.currentDate.getMinutes().toString().padStart(2, '0');
                return `${hours}:${minutes}`;
            }
            font.pixelSize: Appearance.fonts.size.extraLarge * 3
            font.weight: Font.Medium
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSurface
            text: root.getDayName(root.currentDate.getDay())
        }

        StyledText {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            color: Colours.m3Colors.m3OnSurface
            text: `${root.currentDate.getDate()} ${root.getMonthName(root.currentDate.getMonth())}`
        }
    }
}
