pragma ComponentBehavior: Bound

import QtQuick

import qs.Core.Utils

ShaderEffect {
    id: root

    required property real  borderOverlap
    required property color color
    required property real  cornerRadius
    required property real  dockDepth
    required property real  dockLength
    required property real  filletRadius
    required property real  panelDepth
    required property real  panelLength
    required property real  stepFilletRadius

    property color          fillColor: color
    property vector2d       resolution: Qt.vector2d(width, height)

    anchors.fill: parent
    blending: true
    fragmentShader: Paths.projectRoot + "/Assets/shaders/bottomDrawerShape.frag.qsb"
    visible: dockDepth > 0 || panelDepth > 0
}
