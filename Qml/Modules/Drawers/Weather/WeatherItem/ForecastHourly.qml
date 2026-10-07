import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

StyledRect {
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    color: Colours.m3Colors.m3SurfaceContainer
    implicitHeight: content.height
    implicitWidth: parent.width

    ColumnLayout {
        id: content

        implicitWidth: parent.width
        spacing: 0
        visible: Weather.hourlyForecast && Weather.hourlyForecast.length > 0

        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.leftMargin: 15
            Layout.topMargin: 20
            spacing: Appearance.rounding.small

            Icon {
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                font.variableAxes: {
                    "FILL": 10,
                    "opsz": fontInfo.pixelSize,
                    "wght": fontInfo.weight
                }
                icon: "schedule"
                type: Icon.Material
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Bold
                text: qsTr("Hourly forecast")
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: hourlyRow.height
            contentWidth: hourlyRow.width
            flickableDirection: Flickable.HorizontalFlick

            RowLayout {
                id: hourlyRow

                spacing: 8

                Repeater {
                    delegate: StyledRect {
                        id: delegate

                        required property var  modelData

                        readonly property bool isCurrentHour: Weather.isCurrentForecastHour(modelData)

                        implicitHeight: 130
                        implicitWidth: 65
                        radius: Appearance.rounding.normal

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 0
                            spacing: Appearance.spacing.small

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: 40

                                MaterialShape {
                                    anchors.fill: parent
                                    anchors.rightMargin: 3
                                    color: Colours.m3Colors.m3Primary
                                    shape: MaterialShape.Cookie4Sided
                                    visible: delegate.isCurrentHour
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    color: delegate.isCurrentHour ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.Bold
                                    text: (parseInt(delegate.modelData.temperature) || 0) + "°"
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 2

                                StyledText {
                                    color: Colours.m3Colors.m3Primary
                                    font.pixelSize: Appearance.fonts.size.small
                                    font.weight: Font.Bold
                                    text: (parseInt(delegate.modelData.humidity) || 0) + "%"
                                }
                            }

                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                color: Colours.m3Colors.m3Primary
                                font.pixelSize: Appearance.fonts.size.large * 1.5
                                icon: delegate.modelData.weatherIcon
                                type: Icon.Weather
                            }

                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.small
                                font.weight: Font.Bold
                                text: FormatTimeUtils.convertTo12HourCompact((delegate.modelData.time || "").split(" ")[1] || delegate.modelData.time || "")
                            }
                        }
                    }
                    model: ScriptModel {
                        values: Weather.hourlyFromNow(Weather.hourlyForecast)
                    }
                }
            }
        }
    }
}
