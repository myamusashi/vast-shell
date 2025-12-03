import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Components

Slider {
    id: slider

    property color activeColor: Themes.m3Colors.m3Primary
    property color inactiveColor: Themes.m3Colors.m3SecondaryContainer
    property int waveAmplitude: 3
    property real waveFrequency: 10
    property int separatorWidth: 8
    property int separatorHeight: 4

    snapMode: Slider.NoSnap

    background: Item {
        id: bg

        x: slider.leftPadding
        y: slider.topPadding + slider.availableHeight / 2 - height / 2
        width: slider.availableWidth
        height: slider.height

        readonly property real trackStartX: 20
        readonly property real trackEndX: width - 20
        readonly property real trackWidth: trackEndX - trackStartX
        readonly property real normalizedValue: slider.visualPosition

        Canvas {
            id: wavyCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var trackStartX = bg.trackStartX
                var trackWidth = bg.trackWidth
                var normalizedValue = bg.normalizedValue
                var activeWidth = trackWidth * normalizedValue

                var gapOffset = slider.separatorWidth / 2
                activeWidth = Math.max(0, activeWidth - gapOffset)

                if (activeWidth <= 0)
                    return

                ctx.strokeStyle = slider.activeColor
                ctx.lineWidth = 4
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                ctx.beginPath()
                ctx.moveTo(trackStartX, height / 2)

                var steps = Math.max(Math.floor(activeWidth / 3), 30)
                for (var i = 1; i <= steps; i++) {
                    var progress = i / steps
                    var currentProgress = (progress * activeWidth) / trackWidth
                    var x = trackStartX + trackWidth * currentProgress
                    var waveOffset = Math.sin(currentProgress * Math.PI * 2 * slider.waveFrequency) * slider.waveAmplitude
                    var y = height / 2 + waveOffset
                    ctx.lineTo(x, y)
                }

                ctx.stroke()
            }

            Connections {
                target: slider

                function onVisualPositionChanged() {
                    wavyCanvas.requestPaint()
                }
            }
        }

        Canvas {
            id: inactiveCanvas

            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var trackStartX = bg.trackStartX
                var trackWidth = bg.trackWidth
                var normalizedValue = bg.normalizedValue

                var gapOffset = slider.separatorWidth / 2
                var inactiveStartPos = normalizedValue + (gapOffset / trackWidth)
                var inactiveWidth = trackWidth * (1 - inactiveStartPos)

                if (inactiveWidth <= 0 || inactiveStartPos >= 1)
                    return

                ctx.strokeStyle = slider.inactiveColor
                ctx.lineWidth = 4
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                var startX = trackStartX + trackWidth * inactiveStartPos
                var startWaveOffset = Math.sin(normalizedValue * Math.PI * 2 * slider.waveFrequency) * slider.waveAmplitude
                var startY = height / 2 + startWaveOffset

                ctx.beginPath()
                ctx.moveTo(startX, startY)

                var transitionLength = 6
                var transitionSteps = 3

                for (var i = 1; i <= transitionSteps; i++) {
                    var progress = i / transitionSteps
                    var x = startX + (transitionLength * progress)

                    if (x > trackStartX + trackWidth) {
                        x = trackStartX + trackWidth
                    }

                    var dampingFactor = Math.pow(1 - progress, 2)
                    var currentPos = inactiveStartPos + ((x - startX) / trackWidth)
                    var waveOffset = Math.sin(currentPos * Math.PI * 2 * slider.waveFrequency) * slider.waveAmplitude * dampingFactor
                    var y = height / 2 + waveOffset

                    ctx.lineTo(x, y)

                    if (x >= trackStartX + trackWidth) {
                        break
                    }
                }

                ctx.lineTo(trackStartX + trackWidth, height / 2)
                ctx.stroke()
            }

            Connections {
                target: slider

                function onVisualPositionChanged() {
                    inactiveCanvas.requestPaint()
                }
            }
        }
    }

    handle: Rectangle {
        id: handleRect

        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.topPadding + slider.availableHeight / 2 - height / 2 + getHandleWaveOffset()
        width: 20
        height: 20
        radius: Appearance.rounding.full
        color: slider.activeColor
        opacity: slider.hovered ? 1 : 0
        scale: slider.pressed ? 1.3 : 1

        Behavior on scale {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        function getHandleWaveOffset() {
            return Math.sin(slider.visualPosition * Math.PI * 2 * slider.waveFrequency) * slider.waveAmplitude
        }
    }
}
