pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Core.Configs
import qs.Core.Utils

import "../"

Item {
    id: root

    required property color       color
    required property bool        isFocusedMonitor
    required property ShellScreen window
    required property bool        isDockVisible

    readonly property real        borderSize: enableOuterBorder ? outerBorderSize : 0
    readonly property real        effectiveInnerRadius: Math.max(0, Math.min(innerRadius, holeWidth / 2, holeHeight / 2))
    readonly property real        holeBottom: height - bottomThickness
    readonly property real        holeHeight: Math.max(0, height - topThickness - bottomThickness)
    readonly property real        holeLeft: leftThickness
    readonly property real        holeRight: width - rightThickness
    readonly property real        holeTop: topThickness
    readonly property real        holeWidth: Math.max(0, width - leftThickness - rightThickness)

    property real                 barHeight: 40
    property real                 bottomThickness: exclusiveBottom.zone
    property real                 dockHeight: 0
    property bool                 enableOuterBorder: false
    property real                 innerRadius: 24
    property bool                 isBarOpen: false
    property real                 leftThickness: exclusiveLeft.zone
    property real                 outerBorderSize: 0
    property real                 rightThickness: exclusiveRight.zone
    property real                 topThickness: exclusiveTop.zone

    anchors.fill: parent
    Behavior on topThickness {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Scope {

        Exclusion {
            id: exclusiveLeft

            property alias zone: exclusiveLeft.exclusiveZone

            anchors.left: true
            exclusiveZone: root.borderSize
            name: "left"
        }

        Exclusion {
            id: exclusiveTop

            property alias zone: exclusiveTop.exclusiveZone

            anchors.top: true
            exclusiveZone: {
                if (!root.isBarOpen)
                    return root.outerBorderSize;
                if (root.isFocusedMonitor)
                    return root.outerBorderSize + root.barHeight;
                return root.borderSize;
            }
            name: "top"
        }

        Exclusion {
            id: exclusiveRight

            property alias zone: exclusiveRight.exclusiveZone

            anchors.right: true
            exclusiveZone: root.borderSize
            name: "right"
        }

        Exclusion {
            id: exclusiveBottom

            property alias zone: exclusiveBottom.exclusiveZone

            anchors.bottom: true
            exclusiveZone: root.borderSize
            name: "bottom"
        }

        Exclusion {
            id: exclusiveDock

            property alias zone: exclusiveDock.exclusiveZone

            anchors.bottom: true
            exclusiveZone: root.isDockVisible ? root.dockHeight : 0
            name: "dock"
        }
    }

    Rectangle {
        id: topBar

        antialiasing: false
        color: root.color
        height: root.topThickness
        visible: height > 0 && width > 0
        width: root.width
        x: 0
        y: 0
    }

    Rectangle {
        id: bottomBar

        antialiasing: false
        color: root.color
        height: root.bottomThickness
        visible: height > 0 && width > 0
        width: root.width
        x: 0
        y: root.height - height
    }

    Rectangle {
        id: leftBar

        antialiasing: false
        color: root.color
        height: root.holeHeight
        visible: height > 0 && width > 0
        width: root.leftThickness
        x: 0
        y: root.topThickness
    }

    Rectangle {
        id: rightBar

        antialiasing: false
        color: root.color
        height: root.holeHeight
        visible: height > 0 && width > 0
        width: root.rightThickness
        x: root.width - width
        y: root.topThickness
    }

    CornerFillet {
        cornerIndex: 0
        x: root.holeLeft
        y: root.holeTop
    }

    CornerFillet {
        cornerIndex: 1
        x: root.holeRight - width
        y: root.holeTop
    }

    CornerFillet {
        cornerIndex: 2
        x: root.holeRight - width
        y: root.holeBottom - height
    }

    CornerFillet {
        cornerIndex: 3
        x: root.holeLeft
        y: root.holeBottom - height
    }

    component CornerFillet: ShaderEffect {
        required property int cornerIndex

        property real         corner: cornerIndex
        property color        fillColor: root.color
        property real         radius: root.effectiveInnerRadius
        property vector2d     resolution: Qt.vector2d(width, height)

        blending: true
        fragmentShader: Paths.projectRoot + "/Assets/shaders/cornerFillet.frag.qsb"
        height: root.effectiveInnerRadius
        visible: root.effectiveInnerRadius > 0 && root.color.a > 0
        width: root.effectiveInnerRadius
    }
    component Exclusion: PanelWindow { // qmllint disable
        property string name

        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
        implicitHeight: 0
        implicitWidth: 0
        screen: root.window
    }
}
