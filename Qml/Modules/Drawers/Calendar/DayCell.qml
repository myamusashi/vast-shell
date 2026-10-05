pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property date cellDate: modelData.date
    required property int cellHeight
    required property real cellWidth
    required property int currentMonth
    readonly property int dayFontWeight: isToday ? 1000 : (isCurrentMonth ? 600 : 100)
    readonly property int dayOfWeek: cellDate.getDay()
    readonly property int gridColumn: index % 7
    readonly property int gridRow: Math.floor(index / 7)
    property var holidayEntries: {
        if (!Configs.generals.showHolidays)
            return [];
        return HolidayModel.getHolidaysForDate(cellDate);
    }
    property string holidayLabel: {
        if (!Configs.generals.showHolidays)
            return "";
        return HolidayModel.nameForDate(cellDate);
    }
    required property int index
    readonly property bool isCurrentMonth: modelData.month === currentMonth
    readonly property bool isPopoverOpen: openPopoverDate !== null && new Date(openPopoverDate).toDateString() === cellDate.toDateString()
    readonly property bool isToday: modelData.today
    required property var modelData
    required property var openPopoverDate
    property bool showHoliday: {
        if (!Configs.generals.showHolidays)
            return false;
        return HolidayModel.hasHoliday(cellDate);
    }

    signal closePopoverRequested
    signal openPopoverRequested(var date)

    height: cellHeight
    width: cellWidth
    x: gridColumn * cellWidth
    y: gridRow * cellHeight

    StyledRect {
        id: background

        anchors.fill: parent
        color: {
            if (root.isPopoverOpen)
                return Colours.m3Colors.m3SurfaceContainerHigh;
            if (mouseArea.containsMouse && root.isCurrentMonth)
                return Colours.m3Colors.m3SurfaceVariant;
            return "transparent";
        }
        radius: Appearance.rounding.small

        MArea {
            id: mouseArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            visible: root.isCurrentMonth

            onClicked: {
                if (root.showHoliday && root.holidayLabel !== "") {
                    if (root.isPopoverOpen)
                        root.closePopoverRequested();
                    else
                        root.openPopoverRequested(root.cellDate);
                } else {
                    root.closePopoverRequested();
                }
            }
        }
    }
    StyledRect {
        anchors.fill: parent
        anchors.margins: 1
        border.color: root.isToday ? Colours.m3Colors.m3Primary : "transparent"
        border.width: root.isToday ? 1.5 : 0
        color: "transparent"
        radius: Appearance.rounding.small - 1
        visible: root.isToday && !mouseArea.containsMouse
    }
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
            text: Qt.formatDate(root.cellDate, "d")
        }
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 3
            visible: root.showHoliday

            Repeater {
                model: Math.min(root.holidayEntries.length, 3)

                StyledRect {
                    required property int index

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
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small * 0.65
                text: root.holidayEntries.length > 3 ? "+" + (root.holidayEntries.length - 3) : ""
                visible: text !== ""
            }
        }
    }
}
