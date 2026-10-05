pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell.Widgets
import M3Shapes

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

MaterialShape {
    id: shape

    animationDuration: 0
    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Square

    ClippingWrapperRectangle {
        anchors.fill: shape
        color: "transparent"
        radius: Appearance.rounding.large * 1.8

        Wave {
            fillPercentage: Weather.humidity
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.normal
        z: 2

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignCenter
            Layout.fillWidth: true
            Layout.topMargin: 5
            spacing: 0

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: "water_drop"
                type: Icon.Material
            }
            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.Bold
                text: qsTr("Humidity")
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignCenter
            color: Colours.m3Colors.m3Primary
            font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
            font.weight: Font.Bold
            text: Weather.humidity + "%"
        }
        RowLayout {
            Layout.alignment: Qt.AlignBottom | Qt.AlignCenter
            Layout.bottomMargin: 30
            Layout.fillWidth: true
            implicitHeight: 30
            implicitWidth: 30
            spacing: Appearance.spacing.small

            MaterialShape {
                animationDuration: 0
                color: Colours.m3Colors.m3Primary
                implicitHeight: 30
                implicitWidth: 30
                shape: MaterialShape.Circle

                StyledText {
                    anchors.centerIn: parent
                    color: Colours.m3Colors.m3Surface
                    font.pixelSize: Appearance.fonts.size.normal
                    font.weight: Font.DemiBold
                    text: Weather.dewPoint.toFixed(0) + "°"
                }
            }
            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("Dew point")
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }

    component Wave: Shape {
        id: waveShape

        property alias fillPercentage: waveGeo.fillPercentage
        property color waveColor: Qt.alpha(Colours.m3Colors.m3Primary, 0.4)

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: waveShape.waveColor
            strokeColor: "transparent"

            PathSvg {
                path: waveGeo.buildPath()
            }
        }
        QtObject {
            id: waveGeo

            property real amplitude: 3
            property real fillHeight: heightPx * (fillPercentage / 100)
            property real fillPercentage: 0
            readonly property real heightPx: waveShape.parent.height
            property real waveY: heightPx - fillHeight
            property real wavelength: widthPx / 5
            readonly property real widthPx: waveShape.parent.width

            function buildPath() {
                if (fillHeight <= 0)
                    return "M 0 0";

                var points = 100;
                var pathData = "M 0 " + heightPx + " L 0 " + waveY;

                for (var i = 0; i <= points; i++) {
                    var x = (i / points) * widthPx;
                    var y = waveY + Math.sin((x / wavelength) * Math.PI * 2) * amplitude;
                    pathData += " L " + x + " " + y;
                }

                pathData += " L " + widthPx + " " + heightPx + " Z";
                return pathData;
            }
        }
    }
}
