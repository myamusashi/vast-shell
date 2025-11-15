pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

PanelWindow {
    id: window

    property color barColor: "white"

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region {
        item: cornersArea
        intersection: Intersection.Subtract
    }

    anchors {
        left: true
        top: true
        right: true
        bottom: true
    }

    component Corner: WrapperItem {
        id: root

        required property int corner
        property real radius: 20
        required property color color

        x: (corner === 0 || corner === 3) ? 0 : parent.width - radius
        y: (corner === 0 || corner === 1) ? 0 : parent.height - radius
        rotation: corner * 90

        Shape {
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeWidth: 0
                fillColor: root.color
                startX: root.radius

                PathArc {
                    relativeX: -root.radius
                    relativeY: root.radius
                    radiusX: root.radius
                    radiusY: radiusX
                    direction: PathArc.Counterclockwise
                }

                PathLine {
                    relativeX: 0
                    relativeY: -root.radius
                }

                PathLine {
                    relativeX: root.radius
                    relativeY: 0
                }
            }
        }
    }
    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }

    Scope {
        Exclusion {
            name: "left"
            exclusiveZone: leftBar.implicitWidth
            anchors.left: true
        }
        Exclusion {
            name: "top"
            exclusiveZone: root.isBarOpen ? topBar.implicitHeight : 0
            anchors.top: true
        }
        Exclusion {
            name: "right"
            exclusiveZone: rightBar.implicitWidth
            anchors.right: true
        }
        Exclusion {
            name: "bottom"
            exclusiveZone: bottomBar.implicitHeight
            anchors.bottom: true
        }
    }

    // Bars
    Rectangle {
        id: leftBar
        implicitWidth: 0
        implicitHeight: QsWindow.window?.height ?? 0
        color: window.barColor
        anchors.left: parent.left
    }
    Rectangle {
        id: topBar
        implicitWidth: QsWindow.window?.width ?? 0
        implicitHeight: 40
        color: window.barColor
        anchors.top: parent.top
    }
    Rectangle {
        id: rightBar
        implicitWidth: 0
        implicitHeight: QsWindow.window?.height ?? 0
        color: window.barColor
        anchors.right: parent.right
    }
    Rectangle {
        id: bottomBar
        implicitWidth: QsWindow.window?.width ?? 0
        implicitHeight: 0
        color: window.barColor
        anchors.bottom: parent.bottom
    }

    Rectangle {
        id: cornersArea
        implicitWidth: QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth)
        implicitHeight: QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight)
        color: "transparent"
        x: leftBar.implicitWidth
        y: topBar.implicitHeight

        Repeater {
            model: [0, 1, 2, 3]

            Corner {
                required property int modelData
                corner: modelData
                color: window.barColor
            }
        }
    }
}
