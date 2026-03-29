import QtQuick

import qs.Services

import "../Base"

Item {
    id: root

    anchors {
        fill: parent
    }

    property alias source: borderFx.source
    property alias progress: borderFx.progress
    property alias radius: borderFx.radius
    property alias borderWidth: borderFx.borderWidth
    property alias borderColor: borderFx.borderColor
    property alias animDuration: borderAnim.duration
    property alias anim: borderAnim

    ShaderEffect {
        id: borderFx

        anchors {
            fill: parent
        }

        z: 999
        property var source: ({})
        property real progress: 1.0
        property real radius: source.radius
        property real borderWidth: 2.0
        property vector2d resolution: Qt.vector2d(source.width, source.height)
        property color borderColor: Colours.m3Colors.m3Primary

        vertexShader: "root:/Assets/shaders/borderProgress.vert.qsb"
        fragmentShader: "root:/Assets/shaders/borderProgress.frag.qsb"
    }

    NAnim {
        id: borderAnim

        target: borderFx
        property: "progress"
        from: 1.0
        to: 0.0
        duration: 500
        onFinished: borderFx.destroy()
    }
}
