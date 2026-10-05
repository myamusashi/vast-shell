pragma ComponentBehavior: Bound

import QtQuick
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

    content: AQI {
    }

    component AQI: Column {
        id: column

        readonly property var currentScale: scales[selectedTab]
        property string description: currentScale.description
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
        property int selectedTab: 0

        clip: true
        spacing: Appearance.spacing.normal

        anchors {
            fill: parent
            topMargin: 20
        }
        Header {
            icon: "waves"
            title: qsTr("Air quality")

            onClicked: root.isOpen = false
        }
        WrapperRectangle {
            anchors.margins: Appearance.margin.normal
            color: Colours.m3Colors.m3SurfaceContainer
            implicitHeight: parent.height * 0.25
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
                        text: column.currentScale.value
                    }
                    StyledText {
                        color: Colours.m3Colors.m3Primary
                        font.pixelSize: Appearance.fonts.size.normal
                        text: column.currentScale.category
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
                            const scale = column.currentScale;
                            const position = AqiScale.fraction(scale.value, scale.bounds, scale.max);

                            return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                        }
                        y: parent.height / 2 - height / 2

                        Behavior on x {
                            NAnim {
                            }
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
                ConnectedButtonGroup {
                    id: tabGroup

                    Layout.alignment: Qt.AlignHCenter
                    currentIndex: column.selectedTab
                    model: [qsTr("United States AQI"), qsTr("European AQI")]

                    onClicked: index => column.selectedTab = index
                }
            }
        }
        WrapperRectangle {
            color: Colours.m3Colors.m3Surface
            implicitHeight: aqiDescription.contentHeight + 20
            implicitWidth: parent.width
            margin: 20
            radius: Appearance.rounding.small

            border {
                color: Colours.m3Colors.m3OutlineVariant
                width: 1
            }
            StyledText {
                id: aqiDescription

                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: column.description
                textFormat: Text.MarkdownText
                wrapMode: Text.Wrap
            }
        }
    }
}
