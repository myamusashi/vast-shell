import QtQuick
import QtQuick.Controls

import qs.Components.Base
import qs.Core.Configs
import qs.Services

Slider {
    id: slider

    readonly property bool isWavy: Configs.mediaPlayer.sliderType === "Wavy"
    readonly property bool isWaveForm: Configs.mediaPlayer.sliderType === "WaveForm"
    readonly property int stepCount: slider.pressed ? Math.ceil(width / 2.0) : Math.ceil(width / 0.6)

    property color activeColor: Colours.m3Colors.m3Primary
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer
    property int separatorWidth: 8
    property bool enableWave: true
    property real waveTransition: 1.0

    // Wavy
    property int waveAmplitude: 2
    property real waveFrequency: 9.0
    property real waveAnimPhase: 0.0

    // WaveForm
    property real waveFreqBeach: 3.8
    property real wavePow: 0.90
    property real waveFloor: 0.36
    property real waveRamp: 0.1
    property real waveRampIn: 0.1
    property real waveMaxAmpRatio: 0.50
    property real wavePhaseBeach: 0.0
    property real effectiveWaveRamp: slider.waveRamp

    Behavior on effectiveWaveRamp {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    snapMode: Slider.NoSnap
    hoverEnabled: true
    antialiasing: true
    smooth: true
    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    // FrameAnimation adds a fixed delta every frame regardless of the current
    // phase value, so pause/resume has zero effect on perceived speed
    // fmod keeps the value in [0, 2π] without ever accumulating float error
    FrameAnimation {
        id: wavyPhaseDriver

        running: slider.enableWave && slider.isWavy
        // 2000ms full cycle → 2π / 2.0 radians per second
        onTriggered: slider.waveAnimPhase = (slider.waveAnimPhase + Math.PI * 2 * frameTime / 2.0) % (Math.PI * 2)
    }

    FrameAnimation {
        id: waveFormPhaseDriver

        running: slider.enableWave && slider.isWaveForm
        // 3000ms full cycle → 2π / 3.0 radians per second
        onTriggered: slider.wavePhaseBeach = (slider.wavePhaseBeach + Math.PI * 2 * frameTime / 3.0) % (Math.PI * 2)
    }

    background: Item {
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth
        implicitHeight: 40

        ShaderEffect {
            anchors.fill: parent
            visible: slider.isWavy
            blending: true

            property color activeColor: slider.activeColor
            property color inactiveColor: slider.inactiveColor
            property real w: width
            property real cy: height * 0.5
            property real activeW: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
            property real inactSt: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
            property real freq: slider.waveFrequency
            property real amp: slider.waveAmplitude * slider.waveTransition
            property real phase: slider.waveAnimPhase
            property real strokeHalf: 0.75

            vertexShader: "root:/Assets/shaders/wavy.vert.qsb"
            fragmentShader: "root:/Assets/shaders/wavy.frag.qsb"
        }

        ShaderEffect {
            anchors.fill: parent
            visible: slider.isWaveForm
            blending: true

            property color activeColor: slider.activeColor
            property color inactiveColor: slider.inactiveColor
            property real w: width
            property real bl: height * 0.5
            property real amp: height * slider.waveMaxAmpRatio
            property real aEnd: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
            property real iSt: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
            property real pos: slider.visualPosition
            property real phase: slider.wavePhaseBeach
            property real freq: slider.waveFreqBeach
            property real pow_: slider.wavePow
            property real floor_: slider.waveFloor
            property real ramp: slider.effectiveWaveRamp
            property real rampIn: slider.waveRampIn
            property real tr: slider.waveTransition
            property real strokeHalf: 0.9

            vertexShader: "root:/Assets/shaders/waveForm.vert.qsb"
            fragmentShader: "root:/Assets/shaders/waveForm.frag.qsb"
        }
    }

    handle: Item {
        id: handleRoot

        x: slider.leftPadding + slider.visualPosition * slider.availableWidth - implicitWidth / 2
        y: slider.topPadding + slider.availableHeight / 2 - implicitHeight / 2
        implicitWidth: 22
        implicitHeight: 40

        Rectangle {
            anchors.centerIn: parent
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
            visible: slider.isWavy
            scale: slider.pressed ? 1.3 : 1
            Behavior on scale {
                NAnim {}
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: slider.isWaveForm
            width: 6
            height: 20
            radius: 3
            color: slider.activeColor
        }
    }
}
