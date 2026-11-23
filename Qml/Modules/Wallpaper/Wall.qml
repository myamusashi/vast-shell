pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils

Variants {
    model: Configs.wallpaper.enabledWallpaper ? Quickshell.screens : []
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

        BaseWallpaper {
            anchors.fill: parent
        }
    }
}
