pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: canvas

    property int aqi: Weather.usAQI

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

    ColumnLayout {
        spacing: Appearance.spacing.small

        anchors {
            bottomMargin: 20
            fill: parent
            leftMargin: 20
            rightMargin: 20
            topMargin: 20
        }
        RowLayout {
            Layout.alignment: Qt.AlignLeft

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.weight: Font.DemiBold
                icon: "waves"
                type: Icon.Material
            }
            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: qsTr("AQI")
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignRight
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Bold
            text: canvas.aqi
        }
        Item {
            Layout.fillHeight: true
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
                    const position = AqiScale.fraction(canvas.aqi, AqiScale.usaBounds, 500);
                    return Math.min(Math.max(0, position * parent.width - width / 2), parent.width - width);
                }
                y: parent.height / 2 - height / 2

                Behavior on x {
                    NAnim {
                    }
                }
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignRight
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.Medium
            text: AqiScale.categoryFor(canvas.aqi).label
        }
    }
}
