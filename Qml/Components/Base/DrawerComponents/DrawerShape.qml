import QtQuick

import qs.Core.Utils

ShaderEffect {
    id: root

    required property real  attachedFilletRadius
    required property real  borderOverlap
    required property color color
    required property real  cornerRadius
    required property real  drawerDepth
    required property real  drawerLength
    required property real  edgeMode
    required property real  filletRadius
    required property real  freeSidePadding
    required property bool  isFlushToEnd
    required property bool  isFlushToStart
    required property real  startPadding

    property color          fillColor: color
    property real           flushToEnd: isFlushToEnd ? 1.0 : 0.0
    property real           flushToStart: isFlushToStart ? 1.0 : 0.0
    property vector2d       resolution: Qt.vector2d(width, height)

    anchors.fill: parent
    blending: true
    fragmentShader: Paths.projectRoot + "/Assets/shaders/drawerShape.frag.qsb"
    visible: drawerDepth > 0 && drawerLength > 0
}
