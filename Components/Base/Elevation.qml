import QtQuick
import QtQuick.Effects

import qs.Services

// credit: https://github.com/caelestia-dots/shell/blob/main/components/effects/Elevation.qml
RectangularShadow {
    property int level
    property real dp: [0, 1, 3, 6, 8, 12][level]

    color: Qt.alpha(Colours.m3Colors.m3Shadow, 0.7)
    blur: (dp * 5) ** 0.7
    spread: -dp * 0.3 + (dp * 0.1) ** 2
    offset.y: dp / 2

    Behavior on dp {
        NAnim {}
    }
}
