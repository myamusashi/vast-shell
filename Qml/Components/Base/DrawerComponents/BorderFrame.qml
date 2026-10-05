pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

import qs.Core.Configs

import "../"

Item {
    id: root

    property real barHeight: 40
    readonly property real borderSize: enableOuterBorder ? outerBorderSize : 0
    property real bottomThickness: exclusiveBottom.zone
    required property color color
    readonly property real effectiveInnerRadius: Math.max(0, Math.min(innerRadius, holeWidth / 2, holeHeight / 2))
    property bool enableOuterBorder: false
    readonly property real holeBottom: height - bottomThickness
    readonly property real holeHeight: Math.max(0, height - topThickness - bottomThickness)
    readonly property real holeLeft: leftThickness
    readonly property real holeRight: width - rightThickness
    readonly property real holeTop: topThickness
    readonly property real holeWidth: Math.max(0, width - leftThickness - rightThickness)
    property real innerRadius: 24
    property bool isBarOpen: false
    required property bool isFocusedMonitor
    property real leftThickness: exclusiveLeft.zone
    property real outerBorderSize: 0
    property real rightThickness: exclusiveRight.zone
    property real topThickness: exclusiveTop.zone
    required property ShellScreen window

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
    }
    Shape {
        id: shape

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            fillRule: ShapePath.OddEvenFill
            startX: 0
            startY: 0
            strokeColor: "transparent"
            strokeWidth: -1

            PathLine {
                x: root.width
                y: 0
            }
            PathLine {
                x: root.width
                y: root.height
            }
            PathLine {
                x: 0
                y: root.height
            }
            PathLine {
                x: 0
                y: 0
            }
            PathMove {
                x: root.holeLeft + root.effectiveInnerRadius
                y: root.holeTop
            }
            PathLine {
                x: root.holeRight - root.effectiveInnerRadius
                y: root.holeTop
            }
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                x: root.holeRight
                y: root.holeTop + root.effectiveInnerRadius
            }
            PathLine {
                x: root.holeRight
                y: root.holeBottom - root.effectiveInnerRadius
            }
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                x: root.holeRight - root.effectiveInnerRadius
                y: root.holeBottom
            }
            PathLine {
                x: root.holeLeft + root.effectiveInnerRadius
                y: root.holeBottom
            }
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                x: root.holeLeft
                y: root.holeBottom - root.effectiveInnerRadius
            }
            PathLine {
                x: root.holeLeft
                y: root.holeTop + root.effectiveInnerRadius
            }
            PathArc {
                direction: PathArc.Clockwise
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                x: root.holeLeft + root.effectiveInnerRadius
                y: root.holeTop
            }
        }
    }

    component Exclusion: PanelWindow { // qmllint disable
        property string name

        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
        implicitHeight: 0
        implicitWidth: 0
        screen: root.window
    }
}
