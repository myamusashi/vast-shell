import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.Data

PopupWindow {
    id: root

    property bool opened: false
    required property Component content

    color: "transparent"

    visible: opened ? true : false

    implicitWidth: background.width
    implicitHeight: background.height

    StyledRect {
        id: background

        width: 300
        height: 50

        opacity: root.opened ? 1 : 0

        Behavior on opacity {
            NumbAnim {}
        }

        Loader {
            active: root.visible
            sourceComponent: root.content
        }
    }
}
