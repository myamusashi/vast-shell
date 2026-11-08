pragma ComponentBehavior: Bound

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

    Layout.fillHeight: true
    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    Progress {
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.preferredHeight: condition ? 4 : 0
        condition: Weather.isInitialLoading || Weather.isRefreshing
    }

    StyledRect {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.full

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.margin.normal
            anchors.rightMargin: Appearance.margin.normal
            spacing: Appearance.spacing.small

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                icon: "location_on"
                type: Icon.Material
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideRight
                font.pixelSize: Appearance.fonts.size.large
                text: Weather.locationName + ", " + Weather.locationRegion + ", " + Weather.locationCountry
            }

            FloatingButton {
                Layout.alignment: Qt.AlignRight
                backgroundRadius: Appearance.rounding.normal
                color: "transparent"
                enabled: Weather.canRefresh
                icon.color: Colours.m3Colors.m3OnSurface
                icon.name: "refresh"
                icon.size: Appearance.fonts.size.large * 1.5
                implicitHeight: 32
                implicitWidth: 32
                onClicked: Weather.refresh()
            }
        }
    }

    RowLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: Appearance.spacing.normal

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 240
            spacing: Appearance.spacing.normal

            RowLayout {
                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                spacing: Appearance.spacing.small

                StyledText {
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                    font.weight: Font.DemiBold
                    text: Weather.temperature + "°"
                }

                Icon {
                    color: Colours.m3Colors.m3Primary
                    font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
                    icon: Weather.weatherIcon
                    type: Icon.Weather
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignLeft
                spacing: Appearance.spacing.normal

                RowLayout {
                    spacing: Appearance.spacing.small

                    Icon {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        icon: "arrow_upward"
                        type: Icon.Material
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        text: `${Weather.temperatureMax}°`
                    }
                }

                RowLayout {
                    spacing: Appearance.spacing.small

                    Icon {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.normal
                        icon: "arrow_downward"
                        type: Icon.Material
                    }

                    StyledText {
                        color: Colours.m3Colors.m3OnSurface
                        font.pixelSize: Appearance.fonts.size.large
                        font.weight: Font.DemiBold
                        text: `${Weather.temperatureMin}°`
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 240
            spacing: Appearance.spacing.small

            StyledText {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.medium
                font.weight: Font.DemiBold
                text: Weather.weatherCondition
            }

            StyledText {
                Layout.alignment: Qt.AlignTop | Qt.AlignRight
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Feels like %1°").arg(Weather.feelsLike)
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                spacing: Appearance.spacing.small

                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    icon: "update"
                    type: Icon.Material
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: FormatTimeUtils.formatTimestampRelative(parseInt(Weather.lastUpdateWeather))
                }
            }
        }
    }
}
