pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Utils

Variants {
    model: Quickshell.screens
    delegate: PanelWindow {
        id: root

        required property ShellScreen modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: LayerNamespaces.wallpaper
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        screen: modelData
        surfaceFormat.opaque: true

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }

        Wallpaper {
            anchors.fill: parent
        }
    }
}
