pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    component Wind: ScrollView {
        id: scroll

        anchors {
            fill: parent
            topMargin: Appearance.spacing.large
        }

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: availableWidth

        ColumnLayout {
            id: pageContent

            spacing: Appearance.spacing.normal
            width: scroll.availableWidth

            Header {
                icon: "air"
                title: qsTr("Wind")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
                clip: true
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: content.implicitHeight + Appearance.spacing.large
                implicitWidth: parent.width
                margin: Appearance.margin.normal
                radius: Appearance.rounding.normal

                ColumnLayout {
                    id: content

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
                        Layout.alignment: Qt.AlignBottom
                        Layout.fillWidth: true
                        Layout.preferredHeight: sliderRow.implicitHeight
                        Layout.topMargin: 50
                        boundsBehavior: Flickable.StopAtBounds
                        contentHeight: sliderRow.height
                        contentWidth: sliderRow.width
                        flickableDirection: Flickable.HorizontalFlick

                        RowLayout {
                            id: sliderRow

                            anchors.centerIn: parent
                            spacing: Appearance.spacing.large

                            Repeater {
                                model: ScriptModel {
                                    values: Weather.hourlyFromNow(Weather.hourlyForecast)
                                }
                                delegate: ColumnLayout {
                                    required property var modelData

                                    spacing: Appearance.spacing.small

                                    Item {
                                        Layout.fillHeight: true
                                    }

                                    HourlyValueSlider {
                                        from: 0
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

                                    Item {
                                        Layout.fillHeight: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            StyledRect {
                color: Colours.m3Colors.m3Surface
                implicitHeight: description.contentHeight + 20
                implicitWidth: parent.width

                border {
                    color: Colours.m3Colors.m3Outline
                    width: 1
                }

                StyledText {
                    id: description

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: DetailText.wind
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
