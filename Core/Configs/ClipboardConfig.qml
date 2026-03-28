import QtQuick
import Quickshell.Io

JsonObject {
    property bool enabled: false
    property Preview preview: Preview {}

    component Preview: JsonObject {
        property real sourceWidth: 300
        property real sourceHeight: 300
        property real sourceSizeWidth: sourceWidth
        property real sourceSizeHeight: sourceHeight
    }
}
