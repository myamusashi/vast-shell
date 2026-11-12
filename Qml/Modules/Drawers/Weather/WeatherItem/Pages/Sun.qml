pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

import "Markdown"

Pages {
    id: root

    property real sunriseProgress: CelestialProgress.progressBetween(Weather.sunRise, Weather.sunSet)

    content: PageContent {}
    component PageContent: ScrollView {
        id: scroll

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        anchors.fill: parent
        anchors.topMargin: 20
        contentWidth: availableWidth

        Column {
            id: pageContent

            spacing: Appearance.spacing.normal
            width: scroll.availableWidth

            Header {
                icon: "wb_sunny"
                title: qsTr("Sun")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
                color: Colours.m3Colors.m3SurfaceContainer
                implicitHeight: 200
                implicitWidth: parent.width
                radius: Appearance.rounding.normal

                SunShape {
                    sunSize: 40

                    StyledRect {
                        anchors.bottom: parent.bottom
                        clip: true
                        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.4)
                        implicitHeight: parent.height * 0.4
                        implicitWidth: parent.width
                        radius: 0

                        StyledRect {
                            anchors.top: parent.top
                            bottomLeftRadius: Appearance.rounding.normal
                            bottomRightRadius: bottomLeftRadius
                            color: Colours.m3Colors.m3OutlineVariant
                            implicitHeight: 1
                            implicitWidth: parent.width
                            radius: 0
                        }
                    }
                }
            }

            Column {
                spacing: Appearance.spacing.large * 1.5
                width: parent.width

                Row {
                    height: 40
                    width: parent.width

                    Column {
                        spacing: 0
                        width: parent.width / 2

                        StyledText {
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Sunrise")
                            width: parent.width
                        }

                        StyledText {
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            horizontalAlignment: Text.AlignHCenter
                            text: Weather.sunRise
                            width: parent.width
                        }
                    }

                    Column {
                        spacing: 0
                        width: parent.width / 2

                        StyledText {
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.large
                            horizontalAlignment: Text.AlignHCenter
                            text: qsTr("Sunset")
                            width: parent.width
                        }

                        StyledText {
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.extraLarge
                            horizontalAlignment: Text.AlignHCenter
                            text: Weather.sunSet
                            width: parent.width
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
                        text: DetailText.sun
                        textFormat: Text.MarkdownText
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
    component SunShape: ShaderEffect {
        id: sunShape

        property color    bodyColor: sunColor
        property real     bodySize: sunSize
        property color    hillColor: Colours.m3Colors.m3Primary
        property real     progress: root.sunriseProgress
        property vector2d resolution: Qt.vector2d(width, height)
        property color    sunColor: Colours.m3Colors.m3Yellow
        property real     sunSize: 20

        anchors.fill: parent
        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/celestialArc.frag.qsb"
    }
}
