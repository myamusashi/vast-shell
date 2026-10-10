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

    property var uvColors: [Colours.m3Colors.m3Green, Colours.m3Colors.m3Yellow, Colours.m3Colors.m3Orange, Colours.m3Colors.m3Red, Colours.m3Colors.m3Purple]
    property int uvIndex: Weather.uvIndex

    color: Colours.m3Colors.m3SurfaceContainer
    shape: MaterialShape.Cookie12Sided

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
            icon: "sunny"
            type: Icon.Material
        }

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("UV index")
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.weight: Font.Bold
            text: canvas.uvIndex
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            text: Weather.uvCategoryLabel(canvas.uvIndex)
        }
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: 5

            StyledRect {
                id: indicator

                required property int index

                property real         angle: 150 - (index * 30)
                property int          currentCategory: Weather.uvCategoryIndex(canvas.uvIndex)
                property real         distance: Math.min(parent.width, parent.height) * 0.38

                color: index === currentCategory ? canvas.uvColors[index] : Qt.alpha(canvas.uvColors[index], 0.3)
                height: 18
                radius: Appearance.rounding.normal
                width: 18
                x: parent.width / 2 + Math.cos(angle * Math.PI / 180) * distance - width / 2
                y: parent.height / 2 + Math.sin(angle * Math.PI / 180) * distance - height / 2
            }
        }
    }
}
