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

    content: Precipitation {}
    component Precipitation: ScrollView {
        id: scroll

        anchors {
            fill: parent
            topMargin: Appearance.margin.large
        }

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        contentWidth: availableWidth

        ColumnLayout {
            id: pageContent

            spacing: Appearance.spacing.normal
            width: scroll.availableWidth

            Header {
                icon: "rainy"
                title: qsTr("Precipitation")
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
                                    id: precipitationDelegate

                                    required property var modelData

                                    spacing: Appearance.spacing.normal

                                    HourlyValueSlider {
                                        from: 0
                                        handleText: Math.round(value) + "%"
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

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: DetailText.precipitation
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
