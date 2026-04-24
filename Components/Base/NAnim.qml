import QtQuick

import qs.Core.Configs

NumberAnimation {
    id: root

    duration: Appearance.animations.durations.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.animations.curves.standard
}
