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

    content: Precipitation {
    }

    component Precipitation: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }
        Header {
            icon: "rainy"
            title: qsTr("Precipitation")

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
                    text: qsTr("Today's amount")
                }
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        text: Weather.precipitation
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                        text: "mm"
                    }
                }
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    Layout.topMargin: Appearance.margin.large * 2
                    boundsBehavior: Flickable.StopAtBounds
                    contentHeight: sliderRow.height
                    contentWidth: sliderRow.width
                    flickableDirection: Flickable.HorizontalFlick

                    Row {
                        id: sliderRow

                        spacing: Appearance.spacing.large

                        Repeater {
                            delegate: ColumnLayout {
                                id: precipitationDelegate

                                required property var modelData

                                spacing: Appearance.spacing.normal

                                HourlyValueSlider {
                                    from: 0
                                    handleText: Math.round(value) + "%"
                                    implicitHeight: 150
                                    implicitWidth: 30
                                    to: 100
                                    value: precipitationDelegate.modelData.probability
                                }
                                StyledText {
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                    text: FormatTimeUtils.convertTo12HourCompact(precipitationDelegate.modelData.time)
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
        StyledRect {
            color: Colours.m3Colors.m3Surface
            implicitHeight: precipitationDescription.contentHeight + 20
            implicitWidth: parent.width

            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }
            StyledText {
                id: precipitationDescription

                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: DetailText.precipitation
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap

                anchors {
                    fill: parent
                    margins: 10
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }

    // Replaced by shared HourlyValueSlider.qml.
}
