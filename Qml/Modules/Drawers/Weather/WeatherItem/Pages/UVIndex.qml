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
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "wb_sunny"
            title: qsTr("UV Index")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            implicitWidth: parent.width
            implicitHeight: content.width * 0.75
            radius: Appearance.rounding.normal
            clip: true
            color: Colours.m3Colors.m3SurfaceContainer

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Today's average")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.uvIndex
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: Weather.uvCategoryLabel(Weather.uvIndex)
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                                required property var modelData

                                spacing: Appearance.spacing.normal

                                HourlyValueSlider {
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    from: 0
                                    to: 10
                                    value: parent.modelData.uvIndex
                                }

                                StyledText {
                                    text: FormatTimeUtils.convertTo12HourCompact(parent.modelData.time)
                                    color: Colours.m3Colors.m3OnBackground
                                    font.pixelSize: Appearance.fonts.size.normal
                                }
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
            implicitWidth: parent.width
            implicitHeight: uvIndexDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: uvIndexDescription

                anchors.fill: parent
                anchors.margins: 10
                text: DetailText.uvIndex
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
