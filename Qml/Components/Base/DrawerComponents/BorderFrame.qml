import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

import "../"

Item {
    id: root

    anchors.fill: parent
    required property ShellScreen window
    required property color color
    required property bool isFocusedMonitor
    property bool isBarOpen: false
    property real barHeight: 40
    property bool enableOuterBorder: false
    property real outerBorderSize: 0

    readonly property real borderSize: enableOuterBorder ? outerBorderSize : 0

    readonly property real holeWidth: Math.max(0, shape.width - leftThickness - rightThickness)
    readonly property real holeHeight: Math.max(0, shape.height - topThickness - bottomThickness)

    Scope {
        Exclusion {
            id: exclusiveLeft

            anchors.left: true

            property alias zone: exclusiveLeft.exclusiveZone

            name: "left"
            exclusiveZone: root.borderSize
        }
        Exclusion {
            id: exclusiveTop

            anchors.top: true

            property alias zone: exclusiveTop.exclusiveZone

            name: "top"
            exclusiveZone: {
                if (!root.isBarOpen)
                    return root.outerBorderSize;
                if (root.isFocusedMonitor)
                    return root.outerBorderSize + root.barHeight;
                return root.borderSize;
            }
        }
        Exclusion {
            id: exclusiveRight

            anchors.right: true

            property alias zone: exclusiveRight.exclusiveZone

            name: "right"
            exclusiveZone: root.borderSize
        }
        Exclusion {
            id: exclusiveBottom

            anchors.bottom: true

            property alias zone: exclusiveBottom.exclusiveZone

            name: "bottom"
            exclusiveZone: root.borderSize
        }
    }

    property real topThickness: exclusiveTop.zone
    property real bottomThickness: exclusiveBottom.zone
    property real leftThickness: exclusiveLeft.zone
    property real rightThickness: exclusiveRight.zone
    property real innerRadius: 24

    Behavior on topThickness {
        NAnim {}
    }

    readonly property real effectiveInnerRadius: Math.max(0, Math.min(innerRadius, holeWidth / 2, holeHeight / 2))
    readonly property real holeLeft: leftThickness
    readonly property real holeTop: topThickness
    readonly property real holeRight: shape.width - rightThickness
    readonly property real holeBottom: shape.height - bottomThickness

    Shape {
        id: shape

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillColor: root.color
            fillRule: ShapePath.OddEvenFill

            startX: 0
            startY: 0
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
                x: root.holeRight
                y: root.holeTop + root.effectiveInnerRadius
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: root.holeRight
                y: root.holeBottom - root.effectiveInnerRadius
            }
            PathArc {
                x: root.holeRight - root.effectiveInnerRadius
                y: root.holeBottom
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: root.holeLeft + root.effectiveInnerRadius
                y: root.holeBottom
            }
            PathArc {
                x: root.holeLeft
                y: root.holeBottom - root.effectiveInnerRadius
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                direction: PathArc.Clockwise
            }
            PathLine {
                x: root.holeLeft
                y: root.holeTop + root.effectiveInnerRadius
            }
            PathArc {
                x: root.holeLeft + root.effectiveInnerRadius
                y: root.holeTop
                radiusX: root.effectiveInnerRadius
                radiusY: root.effectiveInnerRadius
                direction: PathArc.Clockwise
            }
        }
    }

    component Exclusion: PanelWindow { // qmllint disable
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
