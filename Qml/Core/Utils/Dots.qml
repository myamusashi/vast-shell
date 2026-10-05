import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils

RowLayout {
    id: root

    property alias icon: icon.icon
    property alias iconSize: icon.font.pixelSize
    property alias text: text.text
    property alias textSize: text.font.pixelSize

    anchors.centerIn: parent
    height: parent.height ? parent.height : 1

    WrapperItem {
        id: iconContainer

        Layout.alignment: Qt.AlignVCenter
        implicitHeight: icon.height
        implicitWidth: icon.width

        Icon {
            id: icon

            font.pixelSize: Appearance.fonts.size.medium
        }
    }
    WrapperItem {
        id: textContainer

        Layout.alignment: Qt.AlignVCenter
        implicitHeight: text.height
        implicitWidth: text.width

        StyledText {
            id: text

            font.family: Fonts.mono
            font.pixelSize: Appearance.fonts.size.small
        }
    }
}
