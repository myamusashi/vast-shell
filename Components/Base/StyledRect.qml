import QtQuick

import qs.Core.Configs

Rectangle {
    color: "transparent"
    radius: Appearance.rounding.normal

    Behavior on color {
        CAnim {}
    }
}
