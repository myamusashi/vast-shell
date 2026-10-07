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

    content: UVIndex {}
    component UVIndex: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }

        Header {
            icon: "wb_sunny"
            title: qsTr("UV Index")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            clip: true
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: content.width * 0.75
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
                        text: Weather.uvIndex
                    }

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                        text: Weather.uvCategoryLabel(Weather.uvIndex)
                    }
                }

                Flickable {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
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
                                required property var modelData

                                spacing: Appearance.spacing.normal

                                HourlyValueSlider {
                                    from: 0
                                    implicitHeight: 150
                                    implicitWidth: 30
                                    to: 10
                                    value: parent.modelData.uvIndex
                                }

                                StyledText {
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

                Item {
                    Layout.fillHeight: true
                }
            }
        }

        StyledRect {
            color: Colours.m3Colors.m3Surface
            implicitHeight: uvIndexDescription.contentHeight + 20
            implicitWidth: parent.width

            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: uvIndexDescription

                anchors.fill: parent
                anchors.margins: 10
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: DetailText.uvIndex
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    // Replaced by shared HourlyValueSlider.qml.
}
