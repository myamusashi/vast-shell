import QtQuick

ShaderEffect {
    property real radius: 30
    property color bgColor: "white"
    property int corner: 1 // 0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight

    width: radius
    height: radius

    fragmentShader: "root:/Assets/shaders/Corner.frag.qsb"
}
