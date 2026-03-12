pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Services
import qs.Components.Base

Menu {
    id: root

    implicitWidth: 220
    topPadding: Appearance.spacing.small
    bottomPadding: Appearance.spacing.small
    leftPadding: 0
    rightPadding: 0

    background: Rectangle {
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.large

        Elevation {
            anchors.fill: parent
            z: -1
            level: 3
            radius: parent.radius
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
            NumberAnimation {
                property: "scale"
                from: 0.85
                to: 1.0
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasized
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.85
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }
    }
}
