import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property string pathData
    required property color color

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: -1
        strokeColor: "transparent"
        fillColor: root.color

        PathSvg {
            path: root.pathData
        }
    }
}
