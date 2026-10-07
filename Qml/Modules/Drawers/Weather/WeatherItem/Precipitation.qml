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
    shape: MaterialShape.Square

    ColumnLayout {

        anchors {
            fill: parent
            margins: 20
        }

        RowLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.large * 1.5
                icon: "rainy"
                type: Icon.Material
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: qsTr("Precipitation")
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 0

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.DemiBold
                text: Weather.precipitationDaily
            }

            StyledText {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 5
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                text: "mm"
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: Appearance.spacing.normal

            StyledText {
                Layout.maximumWidth: 70
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                font.weight: Font.DemiBold
                maximumLineCount: 2
                text: qsTr("Total rain for the day")
                wrapMode: Text.WordWrap
            }

            Icon {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                icon: "rainy"
                type: Icon.Material
            }
        }
    }
}
