import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

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
        spacing: Appearance.spacing.small
        visible: Weather.dailyForecast && Weather.dailyForecast.length > 0

        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.leftMargin: 20
            Layout.topMargin: 20
            spacing: Appearance.rounding.small

            Icon {
                color: Colours.m3Colors.m3Primary
                font.pixelSize: Appearance.fonts.size.large
                icon: "calendar_month"
                type: Icon.Material
            }
            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Bold
                text: qsTr("Daily Forecast")
            }
        }
        Flickable {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            contentHeight: dailyRow.height
            contentWidth: dailyRow.width
            flickableDirection: Flickable.HorizontalFlick

            RowLayout {
                id: dailyRow

                spacing: 6

                Repeater {
                    delegate: WrapperRectangle {
                        id: delegate

                        required property var modelData

                        Layout.bottomMargin: 10
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.3)
                        contentInsideBorder: true
                        extraMargin: 10
                        implicitHeight: 210
                        implicitWidth: 60
                        radius: Appearance.rounding.full

                        ColumnLayout {
                            spacing: Appearance.rounding.small

                            ColumnLayout {
                                Layout.alignment: Qt.AlignCenter
                                Layout.margins: 0
                                spacing: 0

                                StyledText {
                                    color: Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                    font.weight: Font.Bold
                                    text: (parseInt(delegate.modelData.maxTemp) || 0) + "°"
                                }
                                StyledText {
                                    color: Colours.m3Colors.m3OnSurface
                                    font.pixelSize: Appearance.fonts.size.normal
                                    text: (parseInt(delegate.modelData.minTemp) || 0) + "°"
                                }
                            }
                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                color: Colours.m3Colors.m3Primary
                                font.pixelSize: Appearance.fonts.size.extraLarge
                                icon: delegate.modelData.weatherIcon
                                type: Icon.Weather
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                color: Colours.m3Colors.m3Primary
                                font.pixelSize: Appearance.fonts.size.small
                                font.weight: Font.Bold
                                text: (parseInt(delegate.modelData.humidity) || 0) + "%"
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                Layout.fillWidth: true
                                Layout.maximumWidth: parent.width
                                color: Colours.m3Colors.m3OnSurface
                                elide: Text.ElideRight
                                font.pixelSize: Appearance.fonts.size.medium
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                maximumLineCount: 2
                                text: {
                                    const date = delegate.modelData.date || "";
                                    if (!date)
                                        return "";
                                    const today = new Date().toDateString();
                                    const forecastDate = new Date(date);
                                    if (forecastDate.toDateString() === today) {
                                        return qsTr("Today");
                                    }
                                    const days = [qsTr("Sun"), qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"), qsTr("Fri"), qsTr("Sat")];
                                    return days[forecastDate.getDay()];
                                }
                                wrapMode: Text.WordWrap
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignCenter
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.medium
                                text: {
                                    const date = delegate.modelData.date || "";
                                    if (!date)
                                        return "";
                                    const parts = date.split("-");
                                    if (parts.length >= 3) {
                                        return parts[2] + "/" + parts[1];
                                    }
                                    return date;
                                }
                            }
                        }
                    }
                    model: ScriptModel {
                        values: [...Weather.dailyForecast]
                    }
                }
            }
        }
    }
}
