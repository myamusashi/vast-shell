pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base
import qs.Components.Button

import "Markdown"

Pages {
    id: root

    content: AQI {}
    component AQI: ScrollView {
        id: scroll

        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        anchors.fill: parent
        anchors.topMargin: 20
        contentWidth: availableWidth

        Column {
            id: pageContent

            readonly property var currentScale: scales[selectedTab]
            readonly property var scales: [
                {
                    description: DetailText.usAQI,
                    value: Weather.usAQI,
                    category: Weather.usAQICategory,
                    bounds: AqiScale.usaBounds,
                    max: 500
                },
                {
                    description: DetailText.euroAQI,
                    value: Weather.europeanAQI,
                    category: Weather.europeanAQICategory,
                    bounds: AqiScale.europeBounds,
                    max: 250
                }
            ]

            property string       description: currentScale.description
            property int          selectedTab: 0

            spacing: Appearance.spacing.normal
            width: scroll.availableWidth

            Header {
                icon: "waves"
                title: qsTr("Air quality")
                onClicked: root.isOpen = false
            }

            WrapperRectangle {
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
                            text: pageContent.currentScale.value
                        }

                        StyledText {
                            color: Colours.m3Colors.m3Primary
                            font.pixelSize: Appearance.fonts.size.normal
                            text: pageContent.currentScale.category
                        }
                    }

                    Item {
                        Layout.bottomMargin: 8
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3

                        StyledRect {
                            implicitHeight: 5
                            implicitWidth: parent.width
                            radius: Appearance.rounding.small
                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    color: Colours.m3Colors.m3Green
                                    position: 0.0
                                }

                                GradientStop {
                                    color: Colours.m3Colors.m3Yellow
                                    position: 0.2
                                }

                                GradientStop {
                                    color: Colours.m3Colors.m3Orange
                                    position: 0.4
                                }

                                GradientStop {
                                    color: Colours.m3Colors.m3Red
                                    position: 0.6
                                }

                                GradientStop {
                                    color: Colours.m3Colors.m3Purple
                                    position: 0.8
                                }

                                GradientStop {
                                    color: Colours.m3Colors.m3Maroon
                                    position: 1.0
                                }
                            }
                        }

                        StyledRect {
                            border.color: Colours.m3Colors.m3OnSurface
                            border.width: 2
                            color: Colours.m3Colors.m3Surface
                            implicitHeight: 15
                            implicitWidth: 15
                            radius: implicitWidth / 2
                            x: {
                                const scale    = pageContent.currentScale;
                                const position = AqiScale.fraction(scale.value, scale.bounds, scale.max);

                                return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                            }
                            y: parent.height / 2 - height / 2
                            Behavior on x {
                                NAnim {}
                            }
                        }
                    }

                    Repeater {
                        model: [
                            {
                                text: qsTr("United States AQI:"),
                                value: Weather.usAQI
                            },
                            {
                                text: qsTr("European AQi:"),
                                value: Weather.europeanAQI
                            }
                        ]
                        delegate: RowLayout {
                            id: aqiDelegate

                            required property var modelData

                            StyledText {
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.large
                                text: aqiDelegate.modelData.text
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            StyledRect {
                                color: Colours.m3Colors.m3Primary
                                implicitHeight: aqiMetrics.height + 5
                                implicitWidth: aqiMetrics.advanceWidth(aqiTextValue.text) + 20
                                radius: Appearance.rounding.full

                                FontMetrics {
                                    id: aqiMetrics

                                    font: aqiTextValue.font
                                }

                                StyledText {
                                    id: aqiTextValue

                                    anchors.centerIn: parent
                                    color: Colours.m3Colors.m3OnPrimary
                                    font.pixelSize: Appearance.fonts.size.large
                                    text: aqiDelegate.modelData.value
                                }
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: tabGroup.implicitHeight
                implicitWidth: parent.width

                ConnectedButtonGroup {
                    id: tabGroup

                    anchors.horizontalCenter: parent.horizontalCenter
                    currentIndex: pageContent.selectedTab
                    model: [qsTr("United States AQI"), qsTr("European AQI")]
                    onClicked: index => pageContent.selectedTab = index
                }
            }

            StyledRect {
                color: Colours.m3Colors.m3Surface
                implicitHeight: aqiDescription.contentHeight + 20
                implicitWidth: parent.width

                border {
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }

                StyledText {
                    id: aqiDescription

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: pageContent.description
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
