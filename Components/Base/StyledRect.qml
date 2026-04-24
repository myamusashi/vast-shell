import QtQuick

import qs.Core.Configs

Rectangle {
    id: root

    implicitWidth: 0
    implicitHeight: 0
    color: "transparent"
    radius: Appearance.rounding.normal

    Behavior on color {
        CAnim {}
    }
}
