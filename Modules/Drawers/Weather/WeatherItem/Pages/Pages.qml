import QtQuick
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    anchors.fill: parent

    required property Component content
    property bool isOpen: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    scale: isOpen ? 1.0 : 0.5
    opacity: isOpen ? 1.0 : 0.0
    transformOrigin: Item.Center
    color: Colours.m3Colors.m3Surface

    transform: Translate {
        x: root.isOpen ? 0 : root.zoomOriginX - root.width / 2
        y: root.isOpen ? 0 : root.zoomOriginY - root.height / 2

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
        Behavior on y {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Loader {
        active: root.isOpen
        asynchronous: true
        sourceComponent: root.content
    }
}
