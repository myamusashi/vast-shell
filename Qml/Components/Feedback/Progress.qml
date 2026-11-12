import QtQuick
import QtQuick.Layouts

import qs.Core.Utils
import qs.Services

import "../Base"

StyledRect {
    id: root

    property alias condition: root.visible
    property alias cornerRadius: background.radius
    property alias indicatorColor: indicatorEffect.indicatorColor
    property alias trackColor: background.color
    property real  waveAmplitude: 0
    property real  waveAnimationPhase: 0
    property real  waveFrequency: 8

    Layout.fillWidth: true
    color: "transparent"
    height: 4
    visible: false

    Rectangle {
        id: background

        anchors.fill: parent
        color: Colours.m3Colors.m3SurfaceContainerHighest
        radius: 2
    }

    ShaderEffect {
        id: indicatorEffect

        readonly property real clampedAmp: Math.min(root.waveAmplitude, root.height * 0.5)

        property real          barEnd: barPosition + barWidth
        property real          barPosition: 0
        property real          barStart: barPosition
        property real          barWidth: root.width * 0.35
        property real          cornerRadius: root.cornerRadius
        property color         indicatorColor: Colours.m3Colors.m3Primary
        property vector2d      resolution: Qt.vector2d(width, height)
        property real          trackHeight: root.height
        property real          waveAmplitude: clampedAmp
        property real          waveFrequency: root.waveFrequency
        property real          wavePhase: root.waveAnimationPhase

        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/linearProgress.frag.qsb"
        height: root.height + clampedAmp * 2
        width: root.width
        x: 0
        y: -clampedAmp

        SequentialAnimation {
            id: loadingAnimation

            loops: Animation.Infinite
            running: root.visible

            ParallelAnimation {

                NAnim {
                    from: root.width * 0.0
                    property: "barWidth"
                    target: indicatorEffect
                    to: root.width * 0.75
                }

                NAnim {
                    from: 0
                    property: "barPosition"
                    target: indicatorEffect
                    to: root.width * 0.25
                }
            }

            ParallelAnimation {

                NAnim {
                    from: root.width * 0.75
                    property: "barWidth"
                    target: indicatorEffect
                    to: root.width * 0.0
                }

                NAnim {
                    from: root.width * 0.25
                    property: "barPosition"
                    target: indicatorEffect
                    to: root.width
                }
            }
        }
    }
}
