import QtQuick
import Quickshell.Io

JsonObject {
    property bool   enabledWallpaper: true
    property bool   livePreview: true
    property string transition: "random"
    property int    transitionDuration: 300
    property bool   transitionLowPerfMode: false
    property int    visibleWallpaper: 3
    property string wallpaperDir: "/home/myamusashi/Pictures/wallpapers"
}
