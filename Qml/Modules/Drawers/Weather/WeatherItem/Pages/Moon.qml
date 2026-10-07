pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    content: Moon {}
    component Moon: ScrollView {
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        anchors.fill: parent
        anchors.topMargin: 20

        Column {
            anchors.fill: parent
            spacing: Appearance.spacing.normal

            Header {
                icon: "bedtime"
                title: qsTr("Moon")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: parent.height * 0.3
                implicitWidth: parent.width
                margin: Appearance.margin.normal
                radius: Appearance.rounding.normal

                RowLayout {

                    ColumnLayout {
                        Layout.alignment: Qt.AlignLeft
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        StyledText {
                            color: Colours.m3Colors.m3OnSurface
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            text: Weather.moonPhaseText(Weather.moonPhase)
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitHeight: illumination.implicitHeight + 15
                            implicitWidth: illumination.implicitWidth + Appearance.margin.normal * 2

                            StyledText {
                                id: illumination

                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                                text: qsTr("Illumination: %1%").arg(Weather.moonIllumination)

                                anchors {
                                    left: parent.left
                                    leftMargin: Appearance.margin.normal
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitHeight: moonRise.implicitHeight + 15
                            implicitWidth: moonRise.implicitWidth + Appearance.margin.normal * 2

                            StyledText {
                                id: moonRise

                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                                text: qsTr("Moonrise: %1").arg(Weather.moonRise)

                                anchors {
                                    left: parent.left
                                    leftMargin: Appearance.margin.normal
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        StyledRect {
                            color: Colours.m3Colors.m3SurfaceContainerHigh
                            implicitHeight: moonSet.implicitHeight + 15
                            implicitWidth: moonSet.implicitWidth + Appearance.margin.normal * 2

                            StyledText {
                                id: moonSet

                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                                text: qsTr("Moonset: %1").arg(Weather.moonSet)

                                anchors {
                                    left: parent.left
                                    leftMargin: Appearance.margin.normal
                                    verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Image {
                        readonly property var moonPhaseMap: ({
                                "New Moon": "NewMoon",
                                "Waxing Crescent": "WaxingCrescentMoon",
                                "First Quarter": "FirstQuarterMoon",
                                "Waxing Gibbous": "WaxingGibbousMoon",
                                "Full Moon": "FullMoon",
                                "Waning Gibbous": "WaningGibbousMoon",
                                "Last Quarter": "LastQuarterMoon",
                                "Waning Crescent": "WaningCrescentMoon"
                            })

                        Layout.preferredHeight: 120
                        Layout.preferredWidth: 120
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: `${Paths.projectRoot}/Assets/weather_icon/${moonPhaseMap[Weather.moonPhase.trim()] ?? "FullMoon"}.svg`
                        sourceSize: Qt.size(120, 120)
                    }
                }
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3Surface
                implicitHeight: pressureDescription.contentHeight + 20
                implicitWidth: parent.width
                margin: 20
                radius: Appearance.rounding.normal

                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }

                StyledText {
                    id: pressureDescription

                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: DetailText.moon
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
