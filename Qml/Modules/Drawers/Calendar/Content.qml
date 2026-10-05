pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Widgets

ColumnLayout {
    id: root

    property date currentDate: new Date()
    property int currentMonth: currentDate.getMonth()
    property int currentYear: currentDate.getFullYear()
    property var monthNames: buildMonthNames()
    property bool showYearMonthPicker: false

    function buildMonthNames(): var {
        const locale = Qt.locale();
        return Array.from({
            length: 12
        }, (_, i) => locale.monthName(i));
    }

    spacing: Appearance.spacing.normal

    Component.onCompleted: Qt.callLater(() => {
        monthNames = buildMonthNames();
        if (Configs.generals.showHolidays)
            HolidayModel.ensureYear(currentYear);
    })
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

        ColumnLayout {
            id: calendarContent

            anchors.fill: parent
            spacing: 0

            Header {
                id: calendarHeader

                currentMonth: root.currentMonth
                currentYear: root.currentYear
                monthNames: root.monthNames

                onNextClicked: {
                    monthGrid.closePopover();
                    root.currentMonth = root.currentMonth + 1;
                    if (root.currentMonth > 11) {
                        root.currentMonth = 0;
                        root.currentYear = root.currentYear + 1;
                    }
                }
                onPrevClicked: {
                    monthGrid.closePopover();
                    root.currentMonth = root.currentMonth - 1;
                    if (root.currentMonth < 0) {
                        root.currentMonth = 11;
                        root.currentYear = root.currentYear - 1;
                    }
                }
                onTitleClicked: {
                    monthGrid.closePopover();
                    root.showYearMonthPicker = !root.showYearMonthPicker;
                }
            }
            CustomDayOfWeekRow {
                id: dayOfWeekRow

                Layout.fillWidth: true
                Layout.preferredHeight: 28

                delegate: Item {
                    id: dayOfWeekItem

                    required property var modelData

                    height: dayOfWeekRow.height
                    width: dayOfWeekRow.cellWidth

                    StyledText {
                        anchors.centerIn: parent
                        color: {
                            if (dayOfWeekItem.modelData.shortName === "Sun" || dayOfWeekItem.modelData.shortName === "Sat")
                                return Colours.m3Colors.m3Error;
                            return Colours.m3Colors.m3OnSurface;
                        }
                        font.pixelSize: Appearance.fonts.size.small * 1.2
                        font.weight: 600
                        horizontalAlignment: Text.AlignHCenter
                        text: dayOfWeekItem.modelData.shortName
                    }
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                clip: false

                CustomMonthGrid {
                    id: monthGrid

                    anchors.fill: parent
                    cellHeight: 34
                    month: root.currentMonth
                    year: root.currentYear

                    delegate: DayCell {
                        cellHeight: monthGrid.cellHeight
                        cellWidth: monthGrid.cellWidth
                        currentMonth: root.currentMonth
                        openPopoverDate: monthGrid.openPopoverDate

                        onClosePopoverRequested: monthGrid.closePopover()
                        onOpenPopoverRequested: date => monthGrid.openPopoverDate = date
                    }
                    popoverDelegate: StyledRect {
                        id: popover

                        property var cellDate
                        readonly property var holidayEntries: cellDate ? HolidayModel.getHolidaysForDate(cellDate) : []
                        readonly property string holidayName: cellDate ? HolidayModel.nameForDate(cellDate) : ""

                        border.color: Qt.alpha(Colours.m3Colors.m3Primary, 0.3)
                        border.width: 1
                        clip: true
                        color: Colours.m3Colors.m3SurfaceContainerHigh
                        implicitHeight: popoverLabel.implicitHeight + 12
                        radius: Appearance.rounding.small

                        Behavior on implicitHeight {
                            NAnim {
                                duration: Appearance.animations.durations.expressiveDefaultSpatial
                                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                            }
                        }

                        StyledText {
                            id: popoverLabel

                            anchors.left: parent.left
                            anchors.margins: 8
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colours.m3Colors.m3OnSurface
                            elide: Text.ElideRight
                            font.pixelSize: Appearance.fonts.size.medium
                            horizontalAlignment: Text.AlignHCenter
                            maximumLineCount: 2
                            text: popover.holidayName
                            wrapMode: Text.WordWrap
                        }
                        MArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: monthGrid.closePopover()
                        }
                    }
                }
            }
        }
        YearMonthPicker {
            anchors.fill: parent
            currentMonth: root.currentMonth
            currentYear: root.currentYear
            visible: root.showYearMonthPicker
            z: 10

            background: StyledRect {
                color: GlobalStates.drawerColors
                radius: Appearance.rounding.medium // qmllint disable
            }

            onMonthPicked: function (month) {
                root.currentMonth = month;
                root.showYearMonthPicker = false;
            }
            onYearPicked: function (year) {
                root.currentYear = year;
                root.showYearMonthPicker = false;
            }
        }
    }
}
