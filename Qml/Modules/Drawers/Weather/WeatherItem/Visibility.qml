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

    Cookie {

        ColumnLayout {
            z: 99

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 20
            }

            RowLayout {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

                Icon {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    icon: "visibility"
                    type: Icon.Material
                }

                StyledText {
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    text: qsTr("Visibility")
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
                text: Weather.visibility.toFixed(0)
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large
                text: "Km"
            }
        }
    }

    component Cookie: Item {
        anchors.centerIn: parent
        implicitHeight: 135
        implicitWidth: 135

        MaterialShape {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            implicitHeight: 135
            implicitWidth: 135
            opacity: 0.5
            shape: MaterialShape.Cookie12Sided
            z: 3
        }

        MaterialShape {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            implicitHeight: 135
            implicitWidth: 135
            opacity: 0.3
            rotation: 7
            shape: MaterialShape.Cookie12Sided
            z: 2
        }

        MaterialShape {
            anchors.centerIn: parent
            color: Colours.m3Colors.m3Primary
            implicitHeight: 135
            implicitWidth: 135
            opacity: 0.2
            rotation: 10
            shape: MaterialShape.Cookie12Sided
            z: 1
        }
    }
}
