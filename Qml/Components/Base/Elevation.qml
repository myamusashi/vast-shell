import QtQuick
import QtQuick.Effects

import qs.Services

// credit: https://github.com/caelestia-dots/shell/blob/main/components/effects/Elevation.qml
RectangularShadow {
    id: root

    property real elevationDp: [0, 1, 3, 6, 8, 12][level]
    property int  level

    anchors.fill: parent
    blur: (elevationDp * 5) ** 0.7
    color: Qt.alpha(Colours.m3Colors.m3Shadow, 0.7)
    offset.y: elevationDp / 2
    spread: -elevationDp * 0.3 + (elevationDp * 0.1) ** 2
    Behavior on elevationDp {
        NAnim {}
    }
}
