import QtQuick

import Quickshell.Io

JsonObject {
	property Apps apps: Apps {}
	property Battery battery: Battery {}

    component Battery: JsonObject {
        property list<var> warnLevels: [
            {
                level: 20,
                title: "Low battery",
                message: "You might want to plug in a charger",
                icon: "battery_android_frame_2"
            },
            {
                level: 10,
                title: "Did you see the previous message?",
                message: "You should probably plug in a charger <b>now</b>",
                icon: "battery_android_frame_1"
            },
            {
                level: 5,
                title: "Critical battery level",
                message: "PLUG THE CHARGER RIGHT NOW!!",
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
        property list<string> audio: ["pavucontrol-qt"]
        property list<string> playback: ["mpv"]
        property list<string> fileExplorer: ["pcmanfm-qt"]
    }
}
