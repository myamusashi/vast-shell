import QtQuick

import qs.Data

Rectangle {
    color: "transparent"
    radius: Appearance.rounding.normal

    Behavior on color {
        ColAnim {}
    }

    Behavior on border.color {
        ColAnim {}
    }
}
