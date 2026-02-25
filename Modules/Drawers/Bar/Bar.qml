import QtQuick
import Quickshell.Widgets

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    implicitWidth: Configs.bar.compact ? parent.width * 0.6 : parent.width
    implicitHeight: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isBarOpen ? 40 : 0

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    WrapperRectangle {
        anchors.fill: parent
        radius: 0
        bottomLeftRadius: Configs.bar.compact ? Appearance.rounding.large : 0
        bottomRightRadius: Configs.bar.compact ? bottomLeftRadius : 0
        color: "transparent"

        Loader {
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && GlobalStates.isBarOpen
            asynchronous: true
            sourceComponent: Item {
                anchors {
                    fill: parent
                    leftMargin: 5
                    rightMargin: 5
                }

                Left {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    monitor: window.modelData
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                }
                Middle {
                    implicitHeight: parent.height
                    implicitWidth: parent.width / 6
                    anchors.centerIn: parent
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
}
