import QtQuick

import Quickshell.Io

JsonObject {
    property Apps apps: Apps {}
    property Battery battery: Battery {}
    property bool followFocusMonitor: true
    property bool transparent: false
    property real alpha: 0.8
    property bool enableOuterBorder: false
    property int outerBorderSize: 10

    component Battery: JsonObject {
        property list<var> warnLevels: [
            {
                level: 20,
                title: qsTr("Low battery"),
                message: qsTr("You might want to plug in a charger"),
                icon: "battery_android_frame_2"
            },
            {
                level: 10,
                title: qsTr("Did you see the previous message?"),
                message: qsTr("You should probably plug in a charger <b>now</b>"),
                icon: "battery_android_frame_1"
            },
            {
                level: 5,
                title: qsTr("Critical battery level"),
                message: qsTr("PLUG THE CHARGER RIGHT NOW!!"),
                icon: "battery_android_alert",
                critical: true
            },
        ]
        property int criticalLevel: 3
    }

    component Apps: JsonObject {
        property string terminal: "foot"
        property string imageViewer: "lximage-qt"
        property string videoViewer: "mpv"
        property string audio: "pavucontrol-qt"
        property string playback: "mpv"
        property string fileExplorer: "pcmanfm-qt"
    }
}
