pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.Core.Configs
import qs.Services

Item {
    id: root

    required property ShellScreen screen

    readonly property var         windows: Hypr.visibleToplevelsOn(root.screen)

    property bool                 screencopyFailed: false

    anchors.fill: parent
    clip: true
    Component.onCompleted: Hyprland.refreshToplevels()

    Repeater {
        model: root.windows
        delegate: Rectangle {
            id: windowCell

            required property HyprlandToplevel modelData

            readonly property var              ipc: modelData.lastIpcObject

            color: "black"
            height: ipc?.size?.[1] ?? 0
            implicitHeight: height
            implicitWidth: width
            width: ipc?.size?.[0] ?? 0
            // Window coordinates are in global virtual-desktop space; offset by
            // the screen origin so each lock surface places only its own output.
            x: (ipc?.at?.[0] ?? 0) - (root.screen?.x ?? 0)
            y: (ipc?.at?.[1] ?? 0) - (root.screen?.y ?? 0)

            ScreencopyView {
                id: screencopyView

                anchors.fill: parent
                captureSource: root.screencopyFailed ? null : windowCell.modelData.wayland
                layer.enabled: true
                live: false
                paintCursor: false
                visible: !root.screencopyFailed && hasContent
                onStopped: root.screencopyFailed = true
                layer.effect: MultiEffect {
                    autoPaddingEnabled: true
                    blur: 1.0
                    blurEnabled: true
                    blurMax: Configs.lockscreen.blurRadius
                }
            }
        }
    }
}
