pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Circle

    MaterialShape {
        anchors.centerIn: parent
        color: Colours.m3Colors.m3Primary
        implicitHeight: 135
        implicitWidth: 135
        opacity: 0.5
        rotation: {
            const direction = Weather.windDirection.toUpperCase();
            const directions = {
                "N": 0,
                "NNE": 22.5,
                "NE": 45,
                "ENE": 67.5,
                "E": 90,
                "ESE": 112.5,
                "SE": 135,
                "SSE": 157.5,
                "S": 180,
                "SSW": 202.5,
                "SW": 225,
                "WSW": 247.5,
                "W": 270,
                "WNW": 292.5,
                "NW": 315,
                "NNW": 337.5
            };
            return directions[direction] || 0;
        }
        shape: MaterialShape.Arrow

        Behavior on rotation {
            NAnim {
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 20

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                font.variableAxes: {
                    "FILL": 10,
                    "opsz": fontInfo.pixelSize,
                    "wght": fontInfo.weight
                }
                icon: "explore"
                type: Icon.Material
            }
            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("Wind")
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.weight: Font.Bold
            text: Weather.windDirection
        }
        StyledText {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            Layout.bottomMargin: 20
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            font.weight: Font.DemiBold
            text: Weather.windSpeed + " Km/h"
        }
    }
}
