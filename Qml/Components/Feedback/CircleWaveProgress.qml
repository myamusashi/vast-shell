pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property real progress: 0.0
    property real strokeWidth: 3.0
    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3OnSurfaceVariant
    property int waveFrequency: Math.round(2 * Math.PI * radius / 15)
    property real waveAmplitude: 1.6
    property real wavePeriod: 2.0
    property real wavePhase: 0.0
    property real trackGap: 4

    property real padding: 2.0

    implicitWidth: 32
    implicitHeight: 32

    readonly property real strokeHalfWidth: strokeWidth * 0.5

    readonly property real radius: Math.max(0, Math.min(width, height) * 0.5 - strokeHalfWidth - waveAmplitude - padding)

    FrameAnimation {
        running: root.visible
        onTriggered: root.wavePhase = (root.wavePhase + Math.PI * 2 * frameTime / root.wavePeriod) % (Math.PI * 2)
    }

    Behavior on progress {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    ShaderEffect {
        anchors.fill: parent
        property real progress: root.progress
        property real radius: root.radius
        property real strokeHalfWidth: root.strokeHalfWidth
        property vector2d resolution: Qt.vector2d(width, height)
        property color activeColor: root.activeColor
        property color inactiveColor: root.inactiveColor
        property real waveFrequency: root.waveFrequency
        property real waveAmplitude: root.waveAmplitude
        property real wavePhase: root.wavePhase
        property real trackGap: root.trackGap

        vertexShader: Paths.projectRoot + "/Assets/shaders/circleWave.vert.qsb"
        fragmentShader: Paths.projectRoot + "/Assets/shaders/circleWave.frag.qsb"
    }
}
