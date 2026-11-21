pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import qs.Core.Configs
import qs.Components.Base.DrawerComponents

WrapperItem {
    id: root

    required property ScreenBorder border

    property real                  barHeight: border.barHeight
    property bool                  open: false

    clip: true
    height: border.topThickness
    leftMargin: Appearance.margin.small
    rightMargin: Appearance.margin.small

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

                spacing: Appearance.spacing.small
                implicitHeight: parent.height
                monitor: root.border.window
            }

            Middle {
                anchors.centerIn: parent
                spacing: Appearance.spacing.small
                implicitHeight: parent.height
                monitor: root.border.window
            }

            Right {

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                layoutDirection: Qt.RightToLeft
                spacing: Appearance.spacing.small
                implicitHeight: parent.height
                monitor: root.border.window
            }
        }
    }
}
