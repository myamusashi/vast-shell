import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.Components

import "Calendar"
import "Launcher"
import "MediaPlayer"
import "QuickSettings"
import "Notifications"
import "Session"
import "Wallpaper"
import "OSD"

PanelWindow {
    id: root

    property alias rectScreen: rect

    color: "transparent"
    anchors {
        top: true
        right: true
        left: true
        bottom: true
    }

    OuterShape {}

    mask: Region {
        x: 0
        y: 0
        width: root.width
        height: root.height
		intersection: Intersection.Xor

        Region {
            item: cal
            intersection: Intersection.Xor
        }
        Region {
            item: app
            intersection: Intersection.Xor
        }
        Region {
            item: mediaPlayer
            intersection: Intersection.Xor
        }
        Region {
            item: quickSettings
            intersection: Intersection.Xor
        }
        Region {
            item: session
            intersection: Intersection.Xor
        }
        Region {
            item: wallpaperSelector
            intersection: Intersection.Xor
        }
        Region {
            item: notif
            intersection: Intersection.Xor
        }
        Region {
            item: notifCenter
            intersection: Intersection.Xor
		}
		Region {
            item: osd
            intersection: Intersection.Xor
        }
    }

    Rectangle {
        id: rect

        anchors.fill: parent
        color: "transparent"

        Calendar {
            id: cal
        }

        App {
            id: app
        }

        MediaPlayer {
            id: mediaPlayer
        }

        QuickSettings {
            id: quickSettings
        }

        Session {
            id: session
        }

        WallpaperSelector {
            id: wallpaperSelector
        }

        Notifications {
            id: notif
        }

        NotificationCenter {
            id: notifCenter
		}

		OSD {
			id: osd
		}
    }
}
