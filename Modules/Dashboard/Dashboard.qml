pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Capture" as Cap
import "History"

PanelWindow {
    id: root

    anchors {
        right: true
        left: true
        bottom: true
        top: true
    }

    color: "transparent"

    screen: Configs.generals.followFocusMonitor ? GlobalStates.getFocusedMonitor : screen
    WlrLayershell.namespace: "shell:dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Normal
    focusable: true
    exclusiveZone: 0
    surfaceFormat.opaque: false
    visible: GlobalStates.isDashboardOpen

    StyledRect {
        anchors.fill: parent
        color: Colours.withAlpha(Colours.m3Colors.m3Surface, 0.3)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 15
            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3
                Layout.topMargin: 15
                Layout.leftMargin: 15
                spacing: Appearance.spacing.large
                Loader {
                    id: captureLoader

                    active: GlobalStates.isDashboardOpen
                    asynchronous: true
                    Layout.preferredWidth: item ? item.implicitWidth + 50 : 200
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    sourceComponent: Cap.Capture {
                        condition: GlobalStates.isDashboardOpen
                    }
                }

                Loader {
                    id: performanceLoader

                    active: GlobalStates.isDashboardOpen
                    asynchronous: true
                    Layout.preferredWidth: item ? item.implicitWidth : 200
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    sourceComponent: Performance {}
                }

                Item {
                    Layout.fillHeight: true
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3
                spacing: Appearance.spacing.large
                // Loader {
                //     id: controlBarLoader
                //
                //     active: GlobalStates.isDashboardOpen
                //     asynchronous: true
                //     Layout.alignment: Qt.AlignHCenter
                //     Layout.preferredHeight: 80
                //     Layout.preferredWidth: parent.width
                //     sourceComponent: ControlBar {}
                // }
                Loader {
                    id: historyLoader

                    active: GlobalStates.isDashboardOpen
                    asynchronous: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: 80
                    Layout.preferredWidth: parent.width
                    sourceComponent: History {}
                }
                Item {
                    Layout.fillHeight: true
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 3
                Layout.rightMargin: 15
                spacing: Appearance.spacing.large
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 100
                    color: "transparent"
                    border.color: Colours.m3Colors.m3Primary
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: qsTr("WIP")
                        color: Colours.m3Colors.m3OnSurface
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
