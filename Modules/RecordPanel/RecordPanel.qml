pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Services
import qs.Components

import "Capture" as Cap

Scope {
    id: scope

    property bool open: false

    GlobalShortcut {
        name: "recordPanel"
        onPressed: scope.open = !scope.open
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: root

            required property ShellScreen modelData
            property int monitorWidth: Hypr.focusedMonitor.width
            property int monitorHeight: Hypr.focusedMonitor.height

            anchors {
                right: true
                left: true
                bottom: true
                top: true
            }
            screen: modelData
            color: "transparent"

            WlrLayershell.namespace: "shell:bar"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Normal
            focusable: true
            exclusiveZone: 0
            surfaceFormat.opaque: false
            visible: scope.open

            StyledRect {
                anchors.fill: parent
                color: Themes.withAlpha(Themes.m3Colors.m3Surface, 0.3)

                ColumnLayout {
                    anchors.left: parent.left
					anchors.top: parent.top
					anchors.leftMargin: 15
                    spacing: Appearance.spacing.large

                    Loader {
                        id: captureLoader
                        active: scope.open
                        asynchronous: true
                        Layout.preferredWidth: item ? item.implicitWidth + 50 : 200
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        sourceComponent: Cap.Capture {
                            condition: scope.open
                        }
                    }

                    Loader {
                        id: performanceLoader
                        active: scope.open
                        asynchronous: true
                        Layout.preferredWidth: item ? item.implicitWidth : 200
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                        sourceComponent: Performance {}
                    }
                }
            }
        }
    }
}
