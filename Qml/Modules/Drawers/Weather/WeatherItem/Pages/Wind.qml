pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    content: Wind {}
    component Wind: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }

        Header {
            icon: "air"
            title: qsTr("Wind")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            clip: true
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: content.implicitHeight + 20
            implicitWidth: parent.width
            margin: 10
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    text: qsTr("Today's average")
                }

                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        text: Weather.windSpeed
                    }

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                        text: "Km/h"
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    Layout.topMargin: Appearance.margin.large * 2
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: sliderRow.height
                    contentWidth: sliderRow.width
                    flickableDirection: Flickable.HorizontalFlick

                    Row {
                        id: sliderRow

                        anchors.centerIn: parent
                        spacing: Appearance.spacing.large

                        Repeater {
                            delegate: ColumnLayout {
                                required property var modelData

                                spacing: Appearance.spacing.small

                                HourlyValueSlider {
                                    from: 0
                                    handleRotation: parent.modelData.windDirectionDegrees
                                    implicitHeight: 150
                                    implicitWidth: 30
                                    to: 15
                                    value: parent.modelData.windSpeed
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                    text: parent.modelData.windSpeed
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                    text: parent.modelData.windDirectionText
                                }

                                StyledText {
                                    Layout.alignment: Qt.AlignCenter
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                    text: FormatTimeUtils.convertTo12HourCompact(parent.modelData.time)
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

        WrapperRectangle {
            color: Colours.m3Colors.m3Surface
            implicitHeight: description.contentHeight + 10
            implicitWidth: parent.width
            margin: 20
            radius: Appearance.rounding.normal

            border {
                color: Colours.m3Colors.m3Outline
                width: 1
            }

            StyledText {
                id: description

                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: DetailText.wind
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
            }
        }
    }

    // Wind uses shared HourlyValueSlider.qml with handleRotation; triangle decoration removed with the local slider.
}
