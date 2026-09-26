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

    property int uvIndex: Weather.uvIndex
    property var uvColors: [Colours.m3Colors.m3Green, Colours.m3Colors.m3Yellow, Colours.m3Colors.m3Orange, Colours.m3Colors.m3Red, Colours.m3Colors.m3Purple]

    RowLayout {
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: 20
        }

        Icon {
            type: Icon.Material
            icon: "sunny"
            font.pixelSize: Appearance.fonts.size.large * 1.5
            color: Colours.m3Colors.m3OnSurface
            font.variableAxes: {
                "FILL": 10,
                "opsz": fontInfo.pixelSize,
                "wght": fontInfo.weight
            }
        }

        StyledText {
            text: qsTr("UV index")
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurface
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Appearance.spacing.normal

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: canvas.uvIndex
            font.pixelSize: Appearance.fonts.size.large * 1.5
            font.weight: Font.Bold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Weather.uvCategoryLabel(canvas.uvIndex)
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurface
        }
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: 5

            StyledRect {
                id: indicator

                required property int index
                property real angle: 150 - (index * 30)
                property real distance: Math.min(parent.width, parent.height) * 0.38
                property int currentCategory: Weather.uvCategoryIndex(canvas.uvIndex)

                width: 18
                height: 18
                radius: Appearance.rounding.normal
                color: index === currentCategory ? canvas.uvColors[index] : Qt.alpha(canvas.uvColors[index], 0.3)

                x: parent.width / 2 + Math.cos(angle * Math.PI / 180) * distance - width / 2
                y: parent.height / 2 + Math.sin(angle * Math.PI / 180) * distance - height / 2
            }
        }
    }
}
