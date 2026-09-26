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

    content: Precipitation {}

    component Precipitation: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "rainy"
            title: qsTr("Precipitation")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            color: Colours.m3Colors.m3SurfaceContainer
            clip: true
            implicitWidth: parent.width
            implicitHeight: content.implicitHeight + 20
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Today's amount")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.precipitation
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: "mm"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    Layout.topMargin: Appearance.margin.large * 2
                    contentWidth: sliderRow.width
                    contentHeight: sliderRow.height
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: sliderRow

                        spacing: Appearance.spacing.large

                        Repeater {
                            model: ScriptModel {
                                values: Weather.hourlyFromNow(Weather.hourlyForecast)
                            }

                            delegate: ColumnLayout {
                                id: precipitationDelegate

                                spacing: Appearance.spacing.normal
                                required property var modelData

                                HourlyValueSlider {
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    from: 0
                                    to: 100
                                    value: precipitationDelegate.modelData.probability
                                    handleText: Math.round(value) + "%"
                                }

                                StyledText {
                                    text: FormatTimeUtils.convertTo12HourCompact(precipitationDelegate.modelData.time)
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            implicitWidth: parent.width
            implicitHeight: precipitationDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: precipitationDescription

                anchors {
                    fill: parent
                    margins: 10
                }
                text: DetailText.precipitation
                color: Colours.m3Colors.m3OnSurface
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.fonts.size.normal
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // Replaced by shared HourlyValueSlider.qml.
}
