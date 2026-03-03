import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Rectangle {
    id: root

    property alias text: textItem.text
    property alias iconName: iconItem.icon
    property int pageIndex: 0
    property bool isActive: pageIndex === settingsWindow.currentPage

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    radius: height / 2

    color: isActive ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    Behavior on color {
        CAnim {}
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.large
        anchors.rightMargin: Appearance.margin.large
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem

            font.pixelSize: Appearance.fonts.size.extraLarge
            color: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Behavior on color {
                CAnim {}
            }
        }

        StyledText {
            id: textItem

            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isActive
            color: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Behavior on color {
                CAnim {}
            }
        }
    }

    MArea {
        id: area

        layerColor: "transparent"
        layerRadius: root.radius
        anchors.fill: parent
        onClicked: settingsWindow.currentPage = root.pageIndex

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: area.containsMouse && !root.isActive ? Qt.rgba(Colours.m3Colors.m3OnSurface.r, Colours.m3Colors.m3OnSurface.g, Colours.m3Colors.m3OnSurface.b, 0.08) : "transparent"
            Behavior on color {
                CAnim {}
            }
        }
    }
}
