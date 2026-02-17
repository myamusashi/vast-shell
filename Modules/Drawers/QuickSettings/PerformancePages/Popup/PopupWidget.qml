pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

import qs.Configs
import qs.Services
import qs.Components

WrapperRectangle {
    id: root

    required property string text
    required property string icon
    required property Component content
    property bool isVisible: false
    property real zoomOriginX: parent.width / 2
    property real zoomOriginY: parent.height / 2

    border {
        width: 1
        color: Colours.m3Colors.m3Outline
    }
    implicitWidth: parent.width * 0.8
    implicitHeight: Math.min(contentColumn.implicitHeight + Appearance.margin.small * 2, parent.height * 0.8)
    margin: Appearance.margin.small
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainer
    scale: isVisible ? 1.0 : 0.5
    opacity: isVisible ? 1.0 : 0.0
    transformOrigin: Item.Center

    transform: Translate {
        x: root.isVisible ? 0 : root.zoomOriginX - root.width / 2
        y: root.isVisible ? 0 : root.zoomOriginY - root.height / 2
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

    ScrollView {
        id: scrollView

        ScrollBar.horizontal.interactive: contentColumn.implicitHeight > scrollView.implicitHeight
        ScrollBar.vertical.interactive: contentColumn.implicitWidth > scrollView.implicitWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentColumn

            width: scrollView.availableWidth
            spacing: 0

            Header {
                Layout.fillWidth: true
                text: root.text
                icon: root.icon
            }

            Loader {
                Layout.fillWidth: true
                Layout.margins: Appearance.margin.normal
                active: root.isVisible
                asynchronous: false
                sourceComponent: root.content
            }
        }
    }
}
