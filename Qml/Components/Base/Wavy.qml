pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Slider {
    id: slider

    property color activeColor: Colours.m3Colors.m3Primary
    property real effectiveWaveRamp: slider.waveRamp
    property bool enableWave: true
    property color inactiveColor: Colours.m3Colors.m3SecondaryContainer
    readonly property bool isWaveForm: Configs.mediaPlayer.sliderType === "WaveForm"
    readonly property bool isWavy: Configs.mediaPlayer.sliderType === "Wavy"
    property int separatorWidth: 8
    readonly property int stepCount: slider.pressed ? Math.ceil(width / 2.0) : Math.ceil(width / 0.6)

    // Wavy
    property int waveAmplitude: 2
    property real waveAnimPhase: 0.0
    property real waveFloor: 0.44

    // WaveForm
    property real waveFreqBeach: 3.8
    property real waveFrequency: 9.0
    property real waveMaxAmpRatio: 0.50
    property real wavePhaseBeach: 0.0
    property real wavePow: 0.90
    property real waveRamp: 0.1
    property real waveRampIn: 0.1
    property real waveTransition: 1.0

    antialiasing: true
    hoverEnabled: true
    smooth: true
    snapMode: Slider.NoSnap

    background: Item {
        implicitHeight: 40
        width: slider.availableWidth
        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2

        Loader {
            active: slider.isWavy
            anchors.fill: parent
            sourceComponent: wavyShaderComponent
        }
        Component {
            id: wavyShaderComponent

            ShaderEffect {
                property color activeColor: slider.activeColor
                property real activeEnd: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
                property real centerY: height * 0.5
                property real effectWidth: width
                property color inactiveColor: slider.inactiveColor
                property real inactiveStart: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
                property real strokeHalfWidth: 0.75
                property real waveAmplitude: slider.waveAmplitude * slider.waveTransition
                property real waveFrequency: slider.waveFrequency
                property real wavePhase: slider.waveAnimPhase

                blending: true
                fragmentShader: Paths.projectRoot + "/Assets/shaders/wavy.frag.qsb"
                vertexShader: Paths.projectRoot + "/Assets/shaders/wavy.vert.qsb"
            }
        }
        Loader {
            active: slider.isWaveForm
            anchors.fill: parent
            sourceComponent: waveFormShaderComponent
        }
    }
    Behavior on effectiveWaveRamp {
        NAnim {
            duration: Appearance.animations.durations.small
        }
    }
    handle: Item {
        id: handleRoot

        implicitHeight: 40
        implicitWidth: 22
        x: slider.leftPadding + slider.visualPosition * slider.availableWidth - implicitWidth / 2
        y: slider.topPadding + slider.availableHeight / 2 - implicitHeight / 2

        Rectangle {
            anchors.centerIn: parent
            color: slider.activeColor
            height: 20
            radius: 3
            scale: slider.pressed ? 1.3 : 1
            visible: slider.isWavy
            width: 6

            Behavior on scale {
                NAnim {
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            color: slider.activeColor
            height: 20
            radius: 3
            visible: slider.isWaveForm
            width: 6
        }
    }
    Behavior on waveTransition {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    onEnableWaveChanged: waveTransition = enableWave ? 1.0 : 0.0

    // FrameAnimation adds a fixed delta every frame regardless of the current
    // wavePhase value, so pause/resume has zero effect on perceived speed.
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
    Component {
        id: waveFormShaderComponent

        ShaderEffect {
            property color activeColor: slider.activeColor
            property real activeEnd: Math.max(0, width * slider.visualPosition - slider.separatorWidth * 0.5)
            property real amplitudeFloor: slider.waveFloor
            property real baselineY: height * 0.5
            property real effectWidth: width
            property color inactiveColor: slider.inactiveColor
            property real inactiveStart: Math.min(width, width * slider.visualPosition + slider.separatorWidth * 0.5)
            property real leadingRamp: slider.waveRampIn
            property real playPosition: slider.visualPosition
            property real playheadRamp: slider.effectiveWaveRamp
            property real shapeExponent: slider.wavePow
            property real strokeHalfWidth: 0.9
            property real transitionAmount: slider.waveTransition
            property real waveAmplitude: height * slider.waveMaxAmpRatio
            property real waveFrequency: slider.waveFreqBeach
            property real wavePhase: slider.wavePhaseBeach

            blending: true
            fragmentShader: Paths.projectRoot + "/Assets/shaders/waveForm.frag.qsb"
            vertexShader: Paths.projectRoot + "/Assets/shaders/waveForm.vert.qsb"
        }
    }
}
