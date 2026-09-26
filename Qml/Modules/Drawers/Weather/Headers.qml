import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button
import qs.Components.Feedback

ColumnLayout {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Appearance.spacing.normal

    function getWeatherCondition(condition) {
        return condition || "";
    }

    Progress {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        condition: Weather.isInitialLoading || Weather.isRefreshing
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: Appearance.rounding.full
        color: Colours.m3Colors.m3SurfaceContainer

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.small

            Icon {
                type: Icon.Material
                icon: "location_on"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }
            StyledText {
                text: Weather.locationName + ", " + Weather.locationRegion + ", " + Weather.locationCountry
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
            }

            Item {
                Layout.fillWidth: true
            }

            FloatingButton {
                Layout.alignment: Qt.AlignRight
                implicitWidth: 32
                implicitHeight: 32
                backgroundRadius: Appearance.rounding.normal
                icon.name: "refresh"
                icon.color: Colours.m3Colors.m3OnSurface
                icon.size: Appearance.fonts.size.large * 1.5
                color: "transparent"
                enabled: Weather.canRefresh
                onClicked: Weather.refresh()
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                spacing: Appearance.spacing.small

                StyledText {
                    text: Weather.temperature + "°"
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                    font.weight: Font.DemiBold
                }

                Icon {
                    type: Icon.Weather
                    icon: Weather.weatherIcon
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                    color: Colours.m3Colors.m3Primary
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                spacing: Appearance.spacing.normal

                Repeater {
                    model: [
                        {
                            text: Weather.temperatureMax + "°",
                            icon: "arrow_upward"
                        },
                        {
                            text: Weather.temperatureMin + "°",
                            icon: "arrow_downward"
                        }
                    ]

                    delegate: RowLayout {
                        required property var modelData

                        spacing: Appearance.spacing.small

                        Icon {
                            type: Icon.Material
                            icon: parent.modelData.icon
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.normal
                        }

                        StyledText {
                            text: parent.modelData.text
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.large
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                text: root.getWeatherCondition(Weather.weatherCondition)
                font.weight: Font.DemiBold
                font.pixelSize: Appearance.fonts.size.medium
                color: Colours.m3Colors.m3OnSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                text: qsTr("Feels like %1°").arg(Weather.feelsLike)
                font.pixelSize: Appearance.fonts.size.small
                color: Colours.m3Colors.m3OnSurface
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                spacing: Appearance.spacing.small

                Icon {
                    type: Icon.Material
                    icon: "update"
                    font.pixelSize: Appearance.fonts.size.normal
                    color: Colours.m3Colors.m3OnSurface
                }

                StyledText {
                    text: FormatTimeUtils.formatTimestampRelative(parseInt(Weather.lastUpdateWeather))
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
