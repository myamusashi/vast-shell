pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property var  cellData
    required property int  cellHeight
    required property real cellWidth
    required property int  currentMonth
    required property int  index

    readonly property int  dayFontWeight: isToday ? 1000 : (isCurrentMonth ? 600 : 100)
    readonly property int  dayOfWeek: cellData.dayOfWeek
    readonly property int  gridColumn: index % 7
    readonly property int  gridRow: Math.floor(index / 7)
    readonly property var  holidayEntries: (Configs.generals.showHolidays && HolidayModel.loaded) ? (HolidayModel.holidaysByDate[cellData.isoDate] ?? []) : []
    readonly property bool isCurrentMonth: cellData.month === currentMonth
    readonly property bool isToday: cellData.today
    readonly property bool showHoliday: holidayEntries.length > 0

    height: cellHeight
    width: cellWidth
    x: gridColumn * cellWidth
    y: gridRow * cellHeight

    Column {
        anchors.centerIn: parent
        spacing: 3
        width: parent.width - 2

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            color: {
                if (root.isToday)
                    return Colours.m3Colors.m3Primary;
                const baseColor = (root.dayOfWeek === 0 || root.dayOfWeek === 6) ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface;
                return root.isCurrentMonth ? baseColor : Qt.alpha(baseColor, 0.2);
            }
            font.pixelSize: Appearance.fonts.size.small * 1.3
            font.weight: root.dayFontWeight
            horizontalAlignment: Text.AlignHCenter
            text: root.cellData.dayNumber
        }

        Loader {
            active: root.showHoliday
            anchors.horizontalCenter: parent.horizontalCenter
            visible: active
            sourceComponent: Row {
                spacing: 3

                Repeater {
                    model: Math.min(root.holidayEntries.length, 3)

                    StyledRect {
                        required property int index

                        anchors.verticalCenter: parent.verticalCenter
                        color: {
                            const entry = root.holidayEntries[index];
                            if (entry && entry.type === "leave")
                                return Colours.m3Colors.m3Secondary;
                            return Colours.m3Colors.m3Tertiary;
                        }
                        implicitHeight: 5
                        implicitWidth: 5
                        radius: 2.5
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.small * 0.65
                    text: root.holidayEntries.length > 3 ? "+" + (root.holidayEntries.length - 3) : ""
                    visible: root.holidayEntries.length > 3
                }
            }
        }
    }
}
