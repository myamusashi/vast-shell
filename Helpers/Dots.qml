import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components
import qs.Configs

RowLayout {
    id: root

    anchors.centerIn: parent

    property alias icon: icon.icon
    property alias text: text.text
    property alias iconSize: icon.font.pixelSize
    property alias textSize: text.font.pixelSize

    height: parent.height ? parent.height : 1

    WrapperItem {
        id: iconContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: icon.width
        implicitHeight: icon.height

        Icon {
            id: icon

            font.pixelSize: Appearance.fonts.size.medium
        }
    }

    WrapperItem {
        id: textContainer

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: text.width
        implicitHeight: text.height

        StyledText {
            id: text

            font.family: Appearance.fonts.family.mono
            font.pixelSize: Appearance.fonts.size.small
        }
    }
}
