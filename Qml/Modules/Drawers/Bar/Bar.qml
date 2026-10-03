import QtQuick
import Quickshell.Widgets

import qs.Components.Base.DrawerComponents

WrapperItem {
    id: root

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    required property ScreenBorder border
    property bool open: false
    property real barHeight: 40

    leftMargin: 5
    rightMargin: 5
    height: border.topThickness
    clip: true
    visible: height > 0

    Loader {
        active: root.open
        height: root.barHeight
        asynchronous: false
        sourceComponent: Item {
            anchors.fill: parent

            Left {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
                monitor: window.modelData // qmllint disable
            }
            Middle {
                anchors.centerIn: parent
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
            }
            Right {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
            }
        }
    }
}
