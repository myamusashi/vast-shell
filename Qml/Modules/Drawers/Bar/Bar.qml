import QtQuick
import Quickshell.Widgets

import qs.Core.Configs
import qs.Components.Base.DrawerComponents

WrapperItem {
    id: root

    required property ScreenBorder border

    property real                  barHeight: 40
    property bool                  open: false

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

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }

                spacing: Appearance.spacing.normal
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
                monitor: window.modelData // qmllint disable

            }

            Middle {
                anchors.centerIn: parent
                spacing: Appearance.spacing.normal
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
            }

            Right {

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                layoutDirection: Qt.RightToLeft
                spacing: Appearance.spacing.normal
                implicitHeight: parent.height
                implicitWidth: parent.width / 6
            }
        }
    }
}
