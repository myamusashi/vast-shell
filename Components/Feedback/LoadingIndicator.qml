import QtQuick

import qs.Services

import M3Shapes

Item {
    id: root

    anchors.centerIn: parent

    property bool status: false
    property double radius: 50
    property double padding: 50
    property double shapePadding: 12
    property var shapeGetters: [MaterialShape.Oval, MaterialShape.SoftBurst, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided]
    property int shapeIndex: 0

    implicitWidth: 30
    implicitHeight: 30
    visible: status

    Timer {
        id: animTimer

        interval: 3000
        running: root.status
        repeat: root.status
        triggeredOnStart: true
        onTriggered: {
            root.shapeIndex = (root.shapeIndex + 1) % root.shapeGetters.length;
            rotationAnim.from = shapeCanvas.rotation;
            rotationAnim.to = shapeCanvas.rotation + 360;
            rotationAnim.restart();
        }
    }

    MaterialShape {
        id: shapeCanvas

        anchors.centerIn: parent
        implicitWidth: parent.width
        implicitHeight: parent.height
        color: Colours.m3Colors.m3Primary
        shape: root.shapeGetters[root.shapeIndex]

        Behavior on shape {
            SpringAnimation {
                spring: 5
                damping: 0.3
                epsilon: 0.1
            }
        }

        NumberAnimation {
            id: rotationAnim

            target: shapeCanvas
            property: "rotation"
            from: 0
            to: 360
            duration: 3000
            easing.type: Easing.OutBack
        }

        scale: root.status ? 1 : 0

        Behavior on scale {
            SpringAnimation {
                spring: 5
                damping: 0.3
                epsilon: 0.1
            }
        }
    }
}
