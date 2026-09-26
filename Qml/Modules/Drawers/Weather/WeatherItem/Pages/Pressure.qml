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

    content: Pressure {}
    component Pressure: Column {
        anchors {
            fill: parent
            topMargin: 20
        }
        clip: true
        spacing: Appearance.spacing.normal

        Header {
            icon: "compress"
            title: qsTr("Pressure")
            onClicked: root.isOpen = false
        }

        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            margin: 10
            clip: true
            implicitWidth: parent.width
            implicitHeight: content.implicitHeight + 20
            radius: Appearance.rounding.normal
            color: Colours.m3Colors.m3SurfaceContainer

            ColumnLayout {
                id: content

                spacing: Appearance.spacing.normal

                StyledText {
                    text: qsTr("Current conditions")
                    color: Colours.m3Colors.m3OnBackground
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                }

                RowLayout {
                    spacing: Appearance.spacing.small
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    StyledText {
                        text: Weather.pressure
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.extraLarge
                    }

                    StyledText {
                        text: "hPa"
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                    }
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
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
                                id: hourlyDelegate

                                required property var modelData
                                required property int index
                                spacing: Appearance.spacing.normal

                                HourlyValueSlider {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 30
                                    implicitHeight: 150
                                    from: 0
                                    to: 1500
                                    value: hourlyDelegate.modelData.pressure
                                    handleIcon: Weather.pressureTrendIcon(hourlyDelegate.modelData.pressure, hourlyDelegate.index)
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: hourlyDelegate.modelData.pressure
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }

                                    StyledText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: FormatTimeUtils.convertTo12HourCompact(hourlyDelegate.modelData.time)
                                        color: Colours.m3Colors.m3OnBackground
                                        font.pixelSize: Appearance.fonts.size.normal
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledRect {
            implicitWidth: parent.width
            implicitHeight: pressureDescription.contentHeight + 20
            color: Colours.m3Colors.m3Surface
            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }

            StyledText {
                id: pressureDescription

                anchors {
                    fill: parent
                    margins: 10
                }
                text: DetailText.pressure
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
