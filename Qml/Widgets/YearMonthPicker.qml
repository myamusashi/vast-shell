pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Control {
    id: root

    property int currentMonth
    property int currentYear
    property int startYear: currentYear - 10

    signal monthPicked(int month)
    signal yearPicked(int year)

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        spacing: Appearance.spacing.normal * 0.5

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            StyledRect {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                color: "transparent"
                radius: Appearance.rounding.full

                Icon {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "chevron_left"
                }
                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.startYear = Math.max(1900, root.startYear - 10)
                }
            }
            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.medium
                font.weight: 600
                horizontalAlignment: Text.AlignHCenter
                text: root.startYear + " \u2013 " + (root.startYear + 9)
            }
            StyledRect {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                color: "transparent"
                radius: Appearance.rounding.full

                Icon {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.large
                    icon: "chevron_right"
                }
                MArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.startYear += 10
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            columnSpacing: 2
            columns: 5
            rowSpacing: 2
            rows: 2

            Repeater {
                model: 10

                delegate: StyledRect {
                    id: yearDelegate

                    required property int index
                    readonly property int year: root.startYear + index

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: year === root.currentYear ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                    radius: Appearance.rounding.small

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.yearPicked(yearDelegate.year)
                    }
                    StyledText {
                        anchors.centerIn: parent
                        color: yearDelegate.year === root.currentYear ? Colours.m3Colors.m3OnPrimaryContainer : Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.medium
                        font.weight: yearDelegate.year === root.currentYear ? 700 : 400
                        text: yearDelegate.year
                    }
                }
            }
        }
        GridLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            columnSpacing: 2
            columns: 4
            rowSpacing: 2
            rows: 3

            Repeater {
                model: 12

                delegate: StyledRect {
                    id: monthDelegate

                    required property int index

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    color: {
                        if (index === root.currentMonth)
                            return Colours.m3Colors.m3PrimaryContainer;
                        return "transparent";
                    }
                    radius: Appearance.rounding.small

                    MArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.monthPicked(monthDelegate.index)
                    }
                    StyledText {
                        anchors.centerIn: parent
                        color: {
                            if (monthDelegate.index === root.currentMonth)
                                return Colours.m3Colors.m3OnPrimaryContainer;
                            return Colours.m3Colors.m3OnSurface;
                        }
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: monthDelegate.index === root.currentMonth ? 600 : 400
                        text: Qt.locale().monthName(monthDelegate.index, Locale.ShortFormat)
                    }
                }
            }
        }
    }
}
