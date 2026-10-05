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
        opacity: 0.6
        shape: MaterialShape.Cookie6Sided
    }
    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 20
        }
        Icon {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
            icon: "cloud"
            type: Icon.Material
        }
        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Cloudiness")
        }
    }
    StyledText {
        anchors.centerIn: parent
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.extraLarge
        text: Weather.cloudCover
    }
    StyledText {
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large
        text: "%"

        anchors {
            bottom: parent.bottom
            bottomMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
    }
}
