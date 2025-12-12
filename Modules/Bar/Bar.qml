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

        Behavior on height {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Loader {
            anchors.fill: parent
            active: window.modelData.name === Hypr.focusedMonitor.name && GlobalStates.isBarOpen
            asynchronous: true
            sourceComponent: RowLayout {
                id: rowbar

                anchors {
                    fill: parent
                    leftMargin: 5
                    rightMargin: 5
                }

                Left {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width / 6
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                Middle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width / 6
                }
                Right {
                    Layout.fillHeight: true
                    Layout.preferredWidth: parent.width / 6
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }
        }
    }
