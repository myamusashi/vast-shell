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
        id: scroll

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        anchors.fill: parent
        anchors.topMargin: 20
        contentWidth: availableWidth

        ColumnLayout {
            id: pageContent

            spacing: Appearance.spacing.normal
            width: scroll.availableWidth

            Header {
                icon: "bedtime"
                title: qsTr("Moon")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: moonRow.implicitHeight + 20
                implicitWidth: parent.width
                margin: 10
                radius: Appearance.rounding.normal

                RowLayout {
                    id: moonRow

                    spacing: Appearance.spacing.large

                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0

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

                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.minimumHeight: 120
                        Layout.minimumWidth: 120
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

            StyledRect {
                color: Colours.m3Colors.m3Surface
                implicitHeight: moonDescription.contentHeight + 20
                implicitWidth: parent.width

                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }

                StyledText {
                    id: moonDescription

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: DetailText.moon
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
