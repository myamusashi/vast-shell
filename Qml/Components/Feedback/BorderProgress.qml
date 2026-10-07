import QtQuick

import qs.Core.Utils
import qs.Services

import "../Base"

Item {
    id: root

    property alias animation: progressAnimation
    property alias animationDuration: progressAnimation.duration
    property alias borderColor: borderEffect.borderColor
    property alias borderWidth: borderEffect.borderWidth
    property alias progress: borderEffect.progress
    property alias radius: borderEffect.radius
    property alias source: borderEffect.source

    anchors.fill: parent

    ShaderEffect {
        id: borderEffect

        property color    borderColor: Colours.m3Colors.m3Primary
        property real     borderWidth: 2.0
        property real     progress: 1.0
        property real     radius: source.radius
        property vector2d resolution: Qt.vector2d(source.width, source.height)
        property var      source: ({})

        anchors.fill: parent
        fragmentShader: Paths.projectRoot + "/Assets/shaders/borderProgress.frag.qsb"
        vertexShader: Paths.projectRoot + "/Assets/shaders/borderProgress.vert.qsb"
        z: 999
    }

    NAnim {
        id: progressAnimation

        duration: 500
        from: 1.0
        property: "progress"
        target: borderEffect
        to: 0.0
        onFinished: borderEffect.destroy()
    }
}
