import QtQuick
import QtQuick.Layouts

import qs.Core.Utils
import qs.Services

import "../Base"

StyledRect {
    id: root

    readonly property real clampedEnd: Math.min(width, barPosition + barWidth)
    readonly property real clampedStart: Math.max(0, barPosition)
    readonly property real drawWidth: Math.max(0, clampedEnd - clampedStart)
    readonly property bool isWavyMode: waveAmplitude > 0.001

    property real          barPosition: 0
    property real          barWidth: root.width * 0.35
    property alias         condition: root.visible
    property alias         cornerRadius: background.radius
    property color         indicatorColor: Colours.m3Colors.m3Primary
    property alias         trackColor: background.color
    property real          waveAmplitude: 0
    property real          waveAnimationPhase: 0
    property real          waveFrequency: 8

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

    Rectangle {
        id: flatIndicator

        color: root.indicatorColor
        height: root.height
        radius: root.cornerRadius
        visible: !root.isWavyMode && root.drawWidth > 0
        width: root.drawWidth
        x: root.clampedStart
        y: 0
    }

    Loader {
        active: root.isWavyMode
        height: root.height + Math.min(root.waveAmplitude, root.height * 0.5) * 2
        width: root.width
        x: 0
        y: -Math.min(root.waveAmplitude, root.height * 0.5)
        sourceComponent: ShaderEffect {
            id: indicatorEffect

            readonly property real clampedAmp: Math.min(root.waveAmplitude, root.height * 0.5)

            property real          barEnd: root.barPosition + root.barWidth
            property real          barStart: root.barPosition
            property real          cornerRadius: root.cornerRadius
            property color         indicatorColor: root.indicatorColor
            property vector2d      resolution: Qt.vector2d(width, height)
            property real          trackHeight: root.height
            property real          waveAmplitude: clampedAmp
            property real          waveFrequency: root.waveFrequency
            property real          wavePhase: root.waveAnimationPhase

            blending: true
            fragmentShader: Paths.projectRoot + "/Assets/shaders/linearProgress.frag.qsb"
        }
    }

    SequentialAnimation {
        id: loadingAnimation

        loops: Animation.Infinite
        running: root.visible

        ParallelAnimation {

            NAnim {
                from: root.width * 0.0
                property: "barWidth"
                target: root
                to: root.width * 0.75
            }

            NAnim {
                from: 0
                property: "barPosition"
                target: root
                to: root.width * 0.25
            }
        }

        ParallelAnimation {

            NAnim {
                from: root.width * 0.75
                property: "barWidth"
                target: root
                to: root.width * 0.0
            }

            NAnim {
                from: root.width * 0.25
                property: "barPosition"
                target: root
                to: root.width
            }
        }
    }
}
