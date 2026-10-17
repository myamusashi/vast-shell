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

        readonly property int   currentMinutes: clock.date.getHours() * 60 + clock.date.getMinutes()
        readonly property real  innerRadius: 4
        readonly property bool  isSunriseDone: currentMinutes >= minutesOfDay(Weather.sunRise)
        readonly property bool  isSunsetDone: currentMinutes >= minutesOfDay(Weather.sunSet)
        readonly property real  outerRadius: 28
        readonly property bool  showSunset: isSunriseDone && !isSunsetDone
        readonly property var   statCells: [
            {
                icon: WeatherIcon.windy,
                label: `${Weather.usAQI} AQI`
            },
            {
                icon: WeatherIcon.humidity,
                label: `${Weather.humidity}%`
            },
            {
                icon: WeatherIcon.hot,
                label: `${Weather.uvIndex} UVI`
            },
            {
                icon: WeatherIcon.thermometer,
                label: qsTr("Feels like %1°").arg(Weather.feelsLike)
            },
            {
                icon: WeatherIcon.raindrops,
                label: `${Weather.precipitationDaily} mm`
            },
            {
                icon: statsGrid.showSunset ? WeatherIcon.sunset : WeatherIcon.sunrise,
                iconColor: statsGrid.showSunset ? Colours.m3Colors.m3Orange : Colours.m3Colors.m3Yellow,
                label: statsGrid.showSunset ? Weather.sunSet : Weather.sunRise
            }
        ]
        readonly property color textColor: Colours.m3Colors.m3Primary

        function                minutesOfDay(clockText: string): int {
            const [hours, minutes] = clockText.split(":").map(Number);
            return hours * 60 + minutes;
        }

        SystemClock {
            id: clock

            precision: SystemClock.Minutes
        }

        Layout.fillHeight: false
        Layout.fillWidth: true
        columnSpacing: 2
        columns: 3
        rowSpacing: 2
        rows: Math.ceil(statCells.length / columns)

        Repeater {
            model: statsGrid.statCells
            delegate: Rectangle {
                id: cell

                required property int  index
                required property var  modelData

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

                RowLayout {
                    id: cellContent

                    anchors.centerIn: parent

                    Icon {
                        color: cell.modelData.iconColor ?? statsGrid.textColor
                        font.pixelSize: Appearance.fonts.size.larger
                        icon: cell.modelData.icon
                        type: Icon.Weather
                    }

                    StyledText {
                        color: statsGrid.textColor
                        font.pixelSize: Appearance.fonts.size.normal
                        text: cell.modelData.label
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

        Flickable {
            id: hourlyFlickable

            readonly property real topSpaceRatio: 0.2

            anchors.fill: parent
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: height
            contentWidth: Math.max(hourlyRow.implicitWidth, width)
            flickableDirection: Flickable.HorizontalFlick

            RowLayout {
                id: hourlyRow

                spacing: 8
                x: Math.max(0, (hourlyFlickable.width - implicitWidth) / 2)
                y: (hourlyFlickable.height - implicitHeight) * hourlyFlickable.topSpaceRatio

                Repeater {
                    model: ScriptModel {
                        values: Weather.hourlyFromNow(Weather.hourlyForecast)
                    }
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

                        implicitHeight: 100
                        implicitWidth: 70
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Appearance.spacing.large

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: 40

                                MaterialShape {
                                    anchors.fill: parent
                                    anchors.rightMargin: 3
                                    color: Colours.m3Colors.m3Primary
                                    shape: MaterialShape.Cookie4Sided
                                    visible: forecastCard.isCurrentHour
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
                }
            }
        }
    }
}
