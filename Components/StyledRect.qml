import QtQuick

import qs.Data

Rectangle {
    color: "transparent"
    radius: Appearance.rounding.normal

    Behavior on color {
        CAnim {}
    }

    Behavior on border.color {
        CAnim {}
    }
}
