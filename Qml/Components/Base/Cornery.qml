pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.Utils

WrapperItem {
    id: root

    property alias color: cornerEffect.fillColor
    property int   corner
    property real  radius: 20

    Component.onCompleted: {
        switch (corner) {
        case 0:
            anchors.left = parent.left;
            anchors.top = parent.top;
            break;
        case 1:
            anchors.top = parent.top;
            anchors.right = parent.right;
            break;
        case 2:
            anchors.right = parent.right;
            anchors.bottom = parent.bottom;
            break;
        case 3:
            anchors.left = parent.left;
            anchors.bottom = parent.bottom;
            break;
        }
    }

    ShaderEffect {
        id: cornerEffect

        property real     corner: root.corner
        property color    fillColor: "transparent"
        property real     radius: root.radius
        property vector2d resolution: Qt.vector2d(width, height)

        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/cornerFillet.frag.qsb"
        implicitHeight: root.radius
        implicitWidth: root.radius
    }
}
