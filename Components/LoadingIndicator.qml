import QtQuick
import Quickshell

import qs.Configs

Item {
    id: loadingSpinner

	property bool status: false

    anchors.centerIn: parent
    width: 30
    height: 30
    visible: status

    property int morphState: 0
    property var morphShapes: [Quickshell.shellDir + "/Assets/m3_shapes/diamond.svg", Quickshell.shellDir + "/Assets/m3_shapes/pill.svg", Quickshell.shellDir + "/Assets/m3_shapes/ghost.svg", Quickshell.shellDir + "/Assets/m3_shapes/flower.svg"]

    Image {
        id: morphingShape

        anchors.fill: parent
        source: loadingSpinner.morphShapes[loadingSpinner.morphState]
        sourceSize: Qt.size(parent.width, parent.height)

        Behavior on source {
            SequentialAnimation {
                NAnim {
                    target: morphingShape
                    property: "scale"
                    to: 0.8
                    duration: Appearance.animations.durations.expressiveEffects
                    easing.bezierCurve: Appearance.animations.curves.expressiveEffects
                }
                PropertyAction {}
                NAnim {
                    target: morphingShape
                    property: "scale"
                    to: 1.0
                    duration: Appearance.animations.durations.expressiveEffects
                    easing.bezierCurve: Appearance.animations.curves.expressiveEffects
                }
            }
        }
    }

    Timer {
        interval: 300
        running: loadingSpinner.visible
        repeat: true
        onTriggered: loadingSpinner.morphState = (loadingSpinner.morphState + 1) % loadingSpinner.morphShapes.length
    }

    RotationAnimator on rotation {
        from: 0
        to: 360
        duration: 500
        loops: Animation.Infinite
        running: loadingSpinner.visible
    }
}
