pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    readonly property real radius: Math.max(0, Math.min(width, height) * 0.5 - strokeHalfWidth - waveAmplitude - padding)
    readonly property real strokeHalfWidth: strokeWidth * 0.5

    property color         activeColor: Colours.m3Colors.m3Primary
    property color         inactiveColor: Colours.m3Colors.m3OnSurfaceVariant
    property real          padding: 2.0
    property real          progress: 0.0
    property real          strokeWidth: 3.0
    property real          trackGap: 4
    property real          waveAmplitude: 1.6
    property int           waveFrequency: Math.round(2 * Math.PI * radius / 15)
    property real          wavePeriod: 2.0
    property real          wavePhase: 0.0

    implicitHeight: 32
    implicitWidth: 32
    Behavior on progress {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    FrameAnimation {
        running: root.visible
        onTriggered: root.wavePhase = (root.wavePhase + Math.PI * 2 * frameTime / root.wavePeriod) % (Math.PI * 2)
    }

    ShaderEffect {
        property color    activeColor: root.activeColor
        property color    inactiveColor: root.inactiveColor
        property real     progress: root.progress
        property real     radius: root.radius
        property vector2d resolution: Qt.vector2d(width, height)
        property real     strokeHalfWidth: root.strokeHalfWidth
        property real     trackGap: root.trackGap
        property real     waveAmplitude: root.waveAmplitude
        property real     waveFrequency: root.waveFrequency
        property real     wavePhase: root.wavePhase

        anchors.fill: parent
        fragmentShader: Paths.projectRoot + "/Assets/shaders/circleWave.frag.qsb"
        vertexShader: Paths.projectRoot + "/Assets/shaders/circleWave.vert.qsb"
    }
}
