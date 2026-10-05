pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs

Transition {
    id: root

    required property bool opening

    ParallelAnimation {
        NAnim {
            duration: root.opening ? Appearance.animations.durations.normal : Appearance.animations.durations.small
            easing.bezierCurve: root.opening ? Appearance.animations.curves.emphasized : Appearance.animations.curves.emphasizedAccel
            from: root.opening ? 0.0 : 1.0
            property: "opacity"
            to: root.opening ? 1.0 : 0.0
        }
        NAnim {
            duration: root.opening ? Appearance.animations.durations.normal : Appearance.animations.durations.small
            easing.bezierCurve: root.opening ? Appearance.animations.curves.emphasized : Appearance.animations.curves.emphasizedAccel
            from: root.opening ? 0.8 : 1.0
            property: "scale"
            to: root.opening ? 1.0 : 0.8
        }
    }
}
