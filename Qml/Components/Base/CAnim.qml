import QtQuick

import qs.Core.Configs

ColorAnimation {
    id: root

    duration: Appearance.animations.durations.normal
    easing.bezierCurve: Appearance.animations.curves.standard
    easing.type: Easing.BezierSpline
}
