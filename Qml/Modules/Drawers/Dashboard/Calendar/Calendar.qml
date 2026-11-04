pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root

    property date currentDate: new Date()
    property int  currentMonth: currentDate.getMonth()
    property int  currentYear: currentDate.getFullYear()
    property var  monthNames: buildMonthNames()
    property var  selectedDate: new Date()
    property bool showYearMonthPicker: false

    function      buildMonthNames(): var {
        const locale = Qt.locale();
        return Array.from({
            length: 12
        }, (unusedValue, monthIndex) => locale.monthName(monthIndex));
    }

    function      stepMonth(delta: int): void {
        let targetMonth = currentMonth + delta;
        let targetYear  = currentYear;
        if (targetMonth > 11) {
            targetMonth = 0;
            targetYear += 1;
        } else if (targetMonth < 0) {
            targetMonth = 11;
            targetYear -= 1;
        }
        if (targetYear !== currentYear)
            currentYear = targetYear;
        currentMonth = targetMonth;
    }

    spacing: Appearance.spacing.normal
    Component.onCompleted: {
        if (Configs.generals.showHolidays)
            HolidayModel.ensureYear(currentYear);
    }
    onCurrentYearChanged: {
        if (Configs.generals.showHolidays)
            HolidayModel.ensureYear(currentYear);
    }

    Timer {
        id: dateTimer

        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            const now = new Date();
            if (now.getDate() !== root.currentDate.getDate())
                root.currentDate = now;
        }
    }

    Connections {

        function onShowHolidaysChanged() {
            if (Configs.generals.showHolidays)
                HolidayModel.ensureYear(root.currentYear);
        }

        target: Configs.generals
    }

    Item {
        Layout.fillHeight: true
        Layout.fillWidth: true
        implicitHeight: calendarContent.implicitHeight

        ColumnLayout {
            id: calendarContent

            anchors.fill: parent
            spacing: 0

            Header {
                id: calendarHeader

                currentMonth: root.currentMonth
                currentYear: root.currentYear
                monthNames: root.monthNames
                onNextClicked: root.stepMonth(1)
                onPrevClicked: root.stepMonth(-1)
                onTitleClicked: root.showYearMonthPicker = !root.showYearMonthPicker
            }

            CustomDayOfWeekRow {
                id: dayOfWeekRow

                Layout.fillWidth: true
                Layout.preferredHeight: 28
                delegate: Item {
                    id: dayOfWeekItem

                    required property int index

                    readonly property int dayOfWeek: dayOfWeekRow.dayOfWeekAt(index)

                    height: dayOfWeekRow.height
                    width: dayOfWeekRow.cellWidth

                    StyledText {
                        anchors.centerIn: parent
                        color: (dayOfWeekItem.dayOfWeek === 0 || dayOfWeekItem.dayOfWeek === 6) ? Colours.m3Colors.m3Error : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small * 1.2
                        font.weight: 600
                        horizontalAlignment: Text.AlignHCenter
                        text: Qt.locale().dayName(dayOfWeekItem.dayOfWeek, Locale.ShortFormat)
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.preferredHeight: monthGrid.cellHeight * 6
                clip: false

                CustomMonthGrid {
                    id: monthGrid

                    anchors.fill: parent
                    cellHeight: 34
                    month: root.currentMonth
                    year: root.currentYear
                    delegate: DayCell {
                        id: dayCellDelegate

                        cellData: monthGrid.cells[dayCellDelegate.index]
                        cellHeight: monthGrid.cellHeight
                        cellWidth: monthGrid.cellWidth
                        currentMonth: root.currentMonth
                    }
                    onDateClicked: clickedDate => root.selectedDate = clickedDate
                }
            }
        }

        Loader {
            active: root.showYearMonthPicker
            anchors.fill: parent
            z: 10
            sourceComponent: YearMonthPicker {
                currentMonth: root.currentMonth
                currentYear: root.currentYear
                background: StyledRect {
                    color: GlobalStates.drawerColors
                    radius: Appearance.rounding.medium // qmllint disable
                }
                onMonthPicked: pickedMonth => {
                    root.currentMonth        = pickedMonth;
                    root.showYearMonthPicker = false;
                }
                onYearPicked: pickedYear => {
                    root.currentYear         = pickedYear;
                    root.showYearMonthPicker = false;
                }
            }
        }
    }
}
