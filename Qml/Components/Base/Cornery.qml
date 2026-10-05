pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets

WrapperItem {
    id: root

    property alias color: shapePath.fillColor
    property int corner
    property real radius: 20

    Component.onCompleted: {
        switch (corner) {
        case 0:
            anchors.left = parent.left;
            anchors.top = parent.top;
            break;
        case 1:
            anchors.top = parent.top;
            anchors.right = parent.right;
            rotation = 90;
            break;
        case 2:
            anchors.right = parent.right;
            anchors.bottom = parent.bottom;
            rotation = 180;
            break;
        case 3:
            anchors.left = parent.left;
            anchors.bottom = parent.bottom;
            rotation = -90;
            break;
        }
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath

            fillColor: "transparent"
            startX: root.radius
            strokeWidth: 0

            PathArc {
                direction: PathArc.Counterclockwise
                radiusX: root.radius
                radiusY: radiusX
                relativeX: -root.radius
                relativeY: root.radius
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
