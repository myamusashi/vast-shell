pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    Layout.fillWidth: true

    RowLayout {
        Layout.fillHeight: false
        spacing: Appearance.spacing.normal

        Icon {
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge * 1.2
            icon: Weather.weatherIcon
            type: Icon.Weather
        }

        ColumnLayout {

            RowLayout {

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.larger
                    font.weight: Font.DemiBold
                    text: `${Weather.temperature}°`
                }

                StyledText {
                    color: Colours.m3Colors.m3Secondary
                    font.pixelSize: Appearance.fonts.size.large
                    text: `${Weather.temperatureMax}° / ${Weather.temperatureMin}°`
                }
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: Weather.weatherCondition
            }
        }
    }

    GridLayout {
        id: statsGrid

        readonly property int   currentMinutes: CelestialProgress.nowMinutes
        readonly property real  innerRadius: 4
        readonly property bool  isSunriseDone: currentMinutes >= CelestialProgress.minutesOf(Weather.sunRise)
        readonly property bool  isSunsetDone: currentMinutes >= CelestialProgress.minutesOf(Weather.sunSet)
        readonly property real  outerRadius: 28
        readonly property bool  showSunset: isSunriseDone && !isSunsetDone
        readonly property int   statCount: 6
        readonly property color textColor: Colours.m3Colors.m3Primary

        function                statIcon(cellIndex: int): string {
            switch (cellIndex) {
            case 0:
                return WeatherIcon.windy;
            case 1:
                return WeatherIcon.humidity;
            case 2:
                return WeatherIcon.hot;
            case 3:
                return WeatherIcon.thermometer;
            case 4:
                return WeatherIcon.raindrops;
            default:
                return showSunset ? WeatherIcon.sunset : WeatherIcon.sunrise;
            }
        }

        function                statIconColor(cellIndex: int): color {
            if (cellIndex === 5)
                return showSunset ? Colours.m3Colors.m3Orange : Colours.m3Colors.m3Yellow;
            return textColor;
        }

        function                statLabel(cellIndex: int): string {
            switch (cellIndex) {
            case 0:
                return `${Weather.usAQI} AQI`;
            case 1:
                return `${Weather.humidity}%`;
            case 2:
                return `${Weather.uvIndex} UVI`;
            case 3:
                return qsTr("Feels like %1°").arg(Weather.feelsLike);
            case 4:
                return `${Weather.precipitationDaily} mm`;
            default:
                return showSunset ? Weather.sunSet : Weather.sunRise;
            }
        }

        Layout.fillHeight: false
        Layout.fillWidth: true
        columnSpacing: 2
        columns: 3
        rowSpacing: 2
        rows: 2

        Repeater {
            model: statsGrid.statCount
            delegate: Rectangle {
                id: cell

                required property int  index

                readonly property int  columnIndex: index % statsGrid.columns
                readonly property bool isFirstColumn: columnIndex === 0
                readonly property bool isFirstRow: rowIndex === 0
                readonly property bool isLastColumn: columnIndex === statsGrid.columns - 1
                readonly property bool isLastRow: rowIndex === statsGrid.rows - 1
                readonly property int  rowIndex: Math.floor(index / statsGrid.columns)

                function               cornerRadius(isOuterCorner: bool): real {
                    return isOuterCorner ? statsGrid.outerRadius : statsGrid.innerRadius;
                }

                Layout.fillWidth: true
                Layout.preferredHeight: cellContent.implicitHeight + Appearance.spacing.large
                bottomLeftRadius: cornerRadius(isLastRow && isFirstColumn)
                bottomRightRadius: cornerRadius(isLastRow && isLastColumn)
                color: Qt.alpha(Colours.m3Colors.m3Primary, 0.3)
                topLeftRadius: cornerRadius(isFirstRow && isFirstColumn)
                topRightRadius: cornerRadius(isFirstRow && isLastColumn)

                Row {
                    id: cellContent

                    anchors.centerIn: parent
                    spacing: 4

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        color: statsGrid.statIconColor(cell.index)
                        font.pixelSize: Appearance.fonts.size.larger
                        icon: statsGrid.statIcon(cell.index)
                        type: Icon.Weather
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        color: statsGrid.textColor
                        font.pixelSize: Appearance.fonts.size.normal
                        text: statsGrid.statLabel(cell.index)
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillHeight: true
        Layout.fillWidth: true
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.1)
        radius: Appearance.rounding.normal

        ListView {
            id: hourlyListView

            readonly property real cardHeight: 100
            readonly property real topSpaceRatio: 0.2

            anchors.fill: parent
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 140
            clip: true
            leftMargin: Math.max(0, (width - contentWidth) / 2)
            orientation: ListView.Horizontal
            spacing: 8
            topMargin: Math.max(0, (height - cardHeight) * topSpaceRatio)
            delegate: StyledRect {
                id: forecastCard

                required property var    modelData

                readonly property string clockTime: {
                    const rawTime = modelData.time || "";
                    return FormatTimeUtils.convertTo12HourCompact(rawTime.split(" ")[1] || rawTime);
                }
                readonly property int    humidity: parseInt(modelData.humidity) || 0
                readonly property bool   isCurrentHour: Weather.isCurrentForecastHour(modelData)
                readonly property int    temperature: parseInt(modelData.temperature) || 0

                implicitHeight: hourlyListView.cardHeight
                implicitWidth: 70
                radius: Appearance.rounding.normal

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Appearance.spacing.large

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 40

                        Loader {
                            active: forecastCard.isCurrentHour
                            anchors.fill: parent
                            anchors.rightMargin: 3
                            sourceComponent: MaterialShape {
                                color: Colours.m3Colors.m3Primary
                                shape: MaterialShape.Cookie4Sided
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            color: forecastCard.isCurrentHour ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                            font.weight: Font.Bold
                            text: `${forecastCard.temperature}°`
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.Bold
                        text: `${forecastCard.humidity}%`
                    }

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.large * 1.5
                        icon: forecastCard.modelData.weatherIcon
                        type: Icon.Weather
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.small
                        font.weight: Font.Bold
                        text: forecastCard.clockTime
                    }
                }
            }
            model: ScriptModel {
                values: Weather.hourlyFromNow(Weather.hourlyForecast)
            }
        }
    }
}
