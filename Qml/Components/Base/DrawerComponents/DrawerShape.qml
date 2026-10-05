import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property color color
    required property string pathData

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        strokeWidth: -1

        PathSvg {
            path: root.pathData
        }
    }
}
