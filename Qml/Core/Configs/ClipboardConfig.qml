import QtQuick
import Quickshell.Io

JsonObject {
    property bool    enabled: false
    property bool    enablePreview: false
    property bool    enableVimKeybinds: true
    property real    height: 700
    property bool    keepOpenAfterCopy: false
    property int     listEntries: 15
    property int     maxEntries: 300
    property Preview preview: Preview {}
    property real    width: 300

    component Preview: JsonObject {
        property real sourceHeight: 300
        property real sourceWidth: 300
    }
}
