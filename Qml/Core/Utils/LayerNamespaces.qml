pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string drawers: "shell:drawers"
    readonly property string dynamicIsland: "shell:dynamicIsland"
    readonly property var    ownNamespaces: [root.drawers, root.wallpaper, root.dynamicIsland, root.screenshotOverlay]
    readonly property string screenshotOverlay: "shell:screenshot-overlay"
    readonly property string wallpaper: "shell:wallpaper"
}
