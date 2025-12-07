import QtQuick
import QtQuick.Effects
import Quickshell

import qs.Configs

Item {
    id: root

    property bool status: false
    property bool withBackground: false

    anchors.centerIn: parent
    implicitWidth: 30
    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        visible: root.withBackground
        color: Themes.withAlpha(Themes.m3Colors.m3Primary, 0.3)
    }

    Item {
        id: loadingSpinner

        anchors.fill: parent
        visible: root.status

        property int morphState: 0
        property real morphProgress: 0
        property var morphShapes: [Quickshell.shellDir + "/Assets/m3_shapes/flower.svg", Quickshell.shellDir + "/Assets/m3_shapes/burst.svg", Quickshell.shellDir + "/Assets/m3_shapes/sunny.svg", Quickshell.shellDir + "/Assets/m3_shapes/soft-burst.svg", Quickshell.shellDir + "/Assets/m3_shapes/hexagon.svg"]

        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 0
            contrast: 0
            saturation: 0
        }

        Item {
            anchors.fill: parent

            Image {
                anchors.fill: parent
                source: loadingSpinner.morphShapes[(loadingSpinner.morphState + 1) % loadingSpinner.morphShapes.length]
                sourceSize: Qt.size(root.implicitWidth, root.implicitHeight)
                smooth: true
            }
        }

        SequentialAnimation {
            running: loadingSpinner.visible
            loops: Animation.Infinite

            ParallelAnimation {
                NAnim {
                    target: root
                    property: "rotation"
                    to: root.rotation + 90
                    duration: Appearance.animations.durations.large
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
                NAnim {
                    target: loadingSpinner
                    property: "morphProgress"
                    from: 0
                    to: 1
                    duration: Appearance.animations.durations.large
                    easing.bezierCurve: Appearance.animations.curves.emphasized
                }
                SequentialAnimation {
                    NAnim {
                        target: loadingSpinner
                        property: "scale"
                        to: 0.85
                        duration: Appearance.animations.durations.emphasizedAccel
                        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
                    }
                    NAnim {
                        target: loadingSpinner
                        property: "scale"
                        to: 1.0
                        duration: Appearance.animations.durations.emphasizedDecel
                        easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                    }
                }
            }
            ScriptAction {
                script: {
                    loadingSpinner.morphState = (loadingSpinner.morphState + 1) % loadingSpinner.morphShapes.length;
                    loadingSpinner.morphProgress = 0;
                    if (root.rotation >= 360)
                        root.rotation = 0;
                }
            }

            PauseAnimation {
                duration: 100
            }
        }
    }
}
