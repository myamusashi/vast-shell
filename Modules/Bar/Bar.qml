import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

ClippingRectangle {
    color: Colours.m3Colors.m3Background
    implicitWidth: parent.width
    implicitHeight: window.modelData.name === Hypr.focusedMonitor.name ? GlobalStates.isBarOpen ? 40 : 10 : 10

    IpcHandler {
        target: "layershell"

        function open(): void {
            GlobalStates.isBarOpen = true;
        }
        function close(): void {
            GlobalStates.isBarOpen = false;
        }
        function toggle(): void {
            GlobalStates.isBarOpen = !GlobalStates.isBarOpen;
        }
    }

    GlobalShortcut {
        name: "layershell"
        onPressed: GlobalStates.isBarOpen = !GlobalStates.isBarOpen
    }

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        anchors.fill: parent
        active: window.modelData.name === Hypr.focusedMonitor.name && GlobalStates.isBarOpen
        asynchronous: true
        sourceComponent: Item {
            id: rowbar

            anchors {
                fill: parent
                leftMargin: 5
                rightMargin: 5
            }

            Left {
                height: parent.height
                width: parent.width / 6
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
            Middle {
                height: parent.height
                width: parent.width / 6
                anchors {
                    centerIn: parent
                }
            }
            Right {
                height: parent.height
                width: parent.width / 6
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
