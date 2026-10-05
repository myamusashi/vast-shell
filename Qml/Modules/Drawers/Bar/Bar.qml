import QtQuick
import Quickshell.Widgets

import qs.Components.Base.DrawerComponents

WrapperItem {
    id: root

    property real barHeight: 40
    required property ScreenBorder border
    property bool open: false

    clip: true
    height: border.topThickness
    leftMargin: 5
    rightMargin: 5
    visible: height > 0

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
    }
    Loader {
        active: root.open
        asynchronous: false
        height: root.barHeight

        sourceComponent: Item {
            anchors.fill: parent

            Left {
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
                monitor: window.modelData // qmllint disable

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
            Middle {
                anchors.centerIn: parent
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
            }
            Right {
                implicitHeight: parent.height
                implicitWidth: parent.width / 6

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
