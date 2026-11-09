pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes

import qs.Components.Base
import qs.Components.Button
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

    ConnectedButtonGrid {
        id: statsGrid

        readonly property int  currentMinutes: CelestialProgress.nowMinutes
        readonly property bool isSunriseDone: currentMinutes >= CelestialProgress.minutesOf(Weather.sunRise)
        readonly property bool isSunsetDone: currentMinutes >= CelestialProgress.minutesOf(Weather.sunSet)
        readonly property bool showSunset: isSunriseDone && !isSunsetDone

        columns: 3
        interactive: false
        model: [
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
                icon: showSunset ? WeatherIcon.sunset : WeatherIcon.sunrise,
                iconColor: showSunset ? Colours.m3Colors.m3Orange : Colours.m3Colors.m3Yellow,
                label: showSunset ? Weather.sunSet : Weather.sunRise
            }
        ]
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
