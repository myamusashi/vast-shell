pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Components

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: root

        required property ShellScreen modelData

        anchors {
            left: true
            right: true
            top: true
            bottom: true
        }

        color: "transparent"
        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        surfaceFormat.opaque: true
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "shell:wallpaper"

        Wallpaper {
            anchors.fill: parent
        }
    }
}
