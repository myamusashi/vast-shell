pragma ComponentBehavior: Bound

import QtQuick

import qs.Services

Rectangle {
    id: root

    readonly property real ratio: Brightness.value / (Brightness.maxValue || 1)

    property int           segmentCount: 20
    property real          segmentMargins: 0.5
    property real          segmentSpacing: 0.5

    signal                 interactEnded
    signal                 interactStarted

    function               commitFromX(x: real): void {
        const usable  = width - segmentMargins * 2;
        const clamped = Math.max(segmentMargins, Math.min(width - segmentMargins, x));
        Brightness.setBrightness(Math.round(((clamped - segmentMargins) / usable) * Brightness.maxValue));
    }

    color: "black"
    implicitHeight: 15
    implicitWidth: 220

    MouseArea {
        id: interactionArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onCanceled: root.interactEnded()
        onPositionChanged: mouse => {
            if (interactionArea.pressed)
                root.commitFromX(mouse.x);
        }
        onPressed: mouse => {
            root.interactStarted();
            root.commitFromX(mouse.x);
        }
        onReleased: root.interactEnded()
    }

    Item {
        id: pill

        anchors.fill: parent

        Row {
            anchors.fill: parent
            anchors.margins: root.segmentMargins
            spacing: root.segmentSpacing

            Repeater {
                model: root.segmentCount
                delegate: Item {
                    id: segmentCell

                    required property int index

                    height: parent.height
                    width: (pill.width - root.segmentMargins * 2 - (root.segmentCount - 1) * root.segmentSpacing) / root.segmentCount

                    Rectangle {
                        id: segment

                        readonly property bool isLit: segmentCell.index < litSegments
                        readonly property int  litSegments: Math.round(root.ratio * root.segmentCount)

                        anchors.centerIn: parent
                        border.color: "black"
                        border.width: 0.5
                        color: isLit ? "white" : "transparent"
                        height: segmentCell.height
                        radius: 0
                        width: segmentCell.width
                    }
                }
            }
        }
    }
}
