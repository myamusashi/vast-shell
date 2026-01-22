pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.Configs
import qs.Helpers
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
            id: wallpaper

            Behavior on source {
                SequentialAnimation {
                    NAnim {
                        target: wallpaper
                        property: "opacity"
                        to: 0
                        duration: Appearance.animations.durations.extraLarge
                    }

                    PropertyAction {}

                    NAnim {
                        target: wallpaper
                        property: "opacity"
                        to: 1
                        duration: Appearance.animations.durations.extraLarge
                    }
                }
            }
        }

        IpcHandler {
            target: "img"

            function set(path: string): void {
                Quickshell.execDetached({
                    "command": ["sh", "-c", "echo " + path + " >" + Paths.currentWallpaperFile + " && " + `matugen image ${path}`]
                });
            }
            function get(): string {
                return Paths.currentWallpaper;
            }
        }
    }
}
