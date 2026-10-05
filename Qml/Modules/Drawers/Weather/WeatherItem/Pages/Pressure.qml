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

    content: Pressure {
    }

    component Pressure: Column {
        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }
        Header {
            icon: "compress"
            title: qsTr("Pressure")

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
                    text: qsTr("Current conditions")
                }
                RowLayout {
                    Layout.alignment: Qt.AlignLeft
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                        text: Weather.pressure
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                        text: "hPa"
                    }
                }
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
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
                                id: hourlyDelegate

                                required property int index
                                required property var modelData

                                spacing: Appearance.spacing.normal

                                HourlyValueSlider {
                                    Layout.alignment: Qt.AlignHCenter
                                    from: 0
                                    handleIcon: Weather.pressureTrendIcon(hourlyDelegate.modelData.pressure, hourlyDelegate.index)
                                    implicitHeight: 150
                                    implicitWidth: 30
                                    to: 1500
                                    value: hourlyDelegate.modelData.pressure
                                }
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                        text: hourlyDelegate.modelData.pressure
                                    }
                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                        text: FormatTimeUtils.convertTo12HourCompact(hourlyDelegate.modelData.time)
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
        StyledRect {
            color: Colours.m3Colors.m3Surface
            implicitHeight: pressureDescription.contentHeight + 20
            implicitWidth: parent.width

            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }
            StyledText {
                id: pressureDescription

                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: DetailText.pressure
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
