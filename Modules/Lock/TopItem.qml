import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Item {
    id: root

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    property alias leftCorner: topLeftCorner
    property alias rightCorner: topRightCorner

    required property bool isLockscreenOpen
    required property color drawerColors
    required property bool locked
    required property bool showErrorMessage

    implicitWidth: root.isLockscreenOpen ? topWrapperRect.implicitWidth : lockIcon.contentWidth
    implicitHeight: 0

    Behavior on implicitWidth {
        NAnim {}
    }

    Corner {
        id: topRightCorner

        location: Qt.TopRightCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    Corner {
        id: topLeftCorner

        location: Qt.TopLeftCorner
        extensionSide: Qt.Horizontal
        radius: 0
        color: root.drawerColors
    }

    WrapperRectangle {
        id: topWrapperRect

        anchors.fill: parent
        color: root.drawerColors
        clip: true
        radius: 0
        leftMargin: Appearance.margin.normal
        rightMargin: Appearance.margin.normal
        bottomLeftRadius: Appearance.rounding.normal
        bottomRightRadius: bottomLeftRadius

        RowLayout {
            spacing: 0

            Icon {
                id: lockIcon

                Layout.alignment: Qt.AlignCenter
                icon: "lock"
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
            }

            WrapperRectangle {
                implicitWidth: root.showErrorMessage ? failText.implicitWidth : 0
                implicitHeight: 40
                color: "transparent"

                StyledText {
                    id: failText

                    text: qsTr("Password Invalid")
                    color: Colours.m3Colors.m3Error
                    font.pixelSize: Appearance.fonts.size.large * 1.5
                    transformOrigin: Item.Left
                }
            }
        }
    }
}
