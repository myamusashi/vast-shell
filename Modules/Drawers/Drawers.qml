import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Calendar"
import "Launcher"
import "MediaPlayer"
import "QuickSettings"
import "Overview"
import "Notifications"
import "Session"
import "WallpaperSelector"
import "Weather"
import "OSD"
import "Bar"
import "Volume"

Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
        id: window

        required property ShellScreen modelData
        readonly property bool needFocusKeyboard: {
            if (GlobalStates.isLauncherOpen)
                return true;
            if (GlobalStates.isSessionOpen && !session.showConfirmDialog)
                return true;
            if (GlobalStates.isWallpaperSwitcherOpen)
                return true;
            if (GlobalStates.isScreenCapturePanelOpen)
                return true;
            return false;
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "shell:drawers"
        WlrLayershell.keyboardFocus: needFocusKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            left: true
            top: true
            right: true
            bottom: true
        }

        mask: Region {
            regions: childRegions.instances
            item: cornersArea
            intersection: Intersection.Subtract
        }

        Variants {
            id: childRegions

            model: window.contentItem.children
            delegate: Region {
                required property Item modelData
                item: modelData
                intersection: Intersection.Xor
            }
        }

        Scope {
            Exclusion {
                id: exclusiveLeft

                anchors.left: true

                property alias zone: exclusiveLeft.exclusiveZone

                screen: window.modelData
                name: "left"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
            Exclusion {
                id: exclusiveTop

                anchors.top: true

                property alias zone: exclusiveTop.exclusiveZone

                screen: window.modelData
                name: "top"
                exclusiveZone: {
                    if (GlobalStates.isBarOpen) {
                        if (window.modelData.name === Hypr.focusedMonitor.name)
                            return Configs.generals.outerBorderSize + Configs.bar.barHeight;
                        else {
                            if (Configs.generals.enableOuterBorder)
                                return Configs.generals.outerBorderSize + Configs.bar.barHeight;
                            else
                                return Configs.bar.barHeight;
                        }
                    } else
                        return Configs.generals.outerBorderSize;
                }
            }
            Exclusion {
                id: exclusiveRight

                anchors.right: true

                property alias zone: exclusiveRight.exclusiveZone

                screen: window.modelData
                name: "right"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
            Exclusion {
                id: exclusiveBottom

                anchors.bottom: true

                property alias zone: exclusiveBottom.exclusiveZone

                screen: window.modelData
                name: "bottom"
                exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
            }
        }

        Rectangle {
            id: rect

            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: leftBar

                anchors.left: parent.left
                implicitWidth: exclusiveLeft.zone
                implicitHeight: QsWindow.window?.height ?? 0
                color: GlobalStates.drawerColors
            }

            Rectangle {
                id: topBar

                anchors.top: parent.top
                implicitWidth: QsWindow.window?.width ?? 0
                implicitHeight: exclusiveTop.zone
                color: GlobalStates.drawerColors

                Behavior on implicitHeight {
                    NAnim {
                        duration: Appearance.animations.durations.expressiveDefaultSpatial
                        easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                    }
                }
            }

            Rectangle {
                id: rightBar

                anchors.right: parent.right
                implicitWidth: exclusiveRight.zone
                implicitHeight: QsWindow.window?.height ?? 0
                color: GlobalStates.drawerColors
            }

            Rectangle {
                id: bottomBar

                anchors.bottom: parent.bottom
                implicitWidth: QsWindow.window?.width ?? 0
                implicitHeight: exclusiveBottom.zone
                color: GlobalStates.drawerColors
            }
        }

        App {
            id: app

            onHeightChanged: window.modelData.name === Hypr.focusedMonitor.name ? osd.anchors.bottomMargin = app.height : 0
        }

        Bar {
            id: bar

            onHeightChanged: {
                cal.anchors.topMargin = exclusiveTop.zone;
                mediaPlayer.anchors.topMargin = exclusiveTop.zone;
                quickSettings.anchors.topMargin = exclusiveTop.zone;
                notif.anchors.topMargin = exclusiveTop.zone;
            }
        }

        Calendar {
            id: cal
        }

        MediaPlayer {
            id: mediaPlayer
        }

        QuickSettings {
            id: quickSettings
        }

        Session {
            id: session

            onWidthChanged: window.modelData.name === Hypr.focusedMonitor.name ? volume.anchors.rightMargin = session.width : 0
        }

        WallpaperSelector {
            id: wallpaperSelector
        }

        Screencapture {
            id: screenCapture
        }

        Overview {}

        Notifications {
            id: notif
        }

        Weathers {}

        OSD {
            id: osd
        }

        Volume {
            id: volume
        }

        Rectangle {
            id: cornersArea

            implicitWidth: QsWindow.window?.width - (leftBar.implicitWidth + rightBar.implicitWidth)
            implicitHeight: QsWindow.window?.height - (topBar.implicitHeight + bottomBar.implicitHeight)
            color: "transparent"
            x: leftBar.implicitWidth
            y: topBar.implicitHeight

            Repeater {
                model: [0, 1, 2, 3]
                Cornery {
                    required property int modelData
                    corner: modelData
                    color: GlobalStates.drawerColors
                }
            }
        }
    }

    component Exclusion: PanelWindow {
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }

    component Cornery: WrapperItem {
        id: root

        property int corner
        property real radius: 20
        property color color

        Component.onCompleted: {
            switch (corner) {
            case 0:
                anchors.left = parent.left;
                anchors.top = parent.top;
                break;
            case 1:
                anchors.top = parent.top;
                anchors.right = parent.right;
                rotation = 90;
                break;
            case 2:
                anchors.right = parent.right;
                anchors.bottom = parent.bottom;
                rotation = 180;
                break;
            case 3:
                anchors.left = parent.left;
                anchors.bottom = parent.bottom;
                rotation = -90;
                break;
            }
        }

        Shape {
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 0
                fillColor: root.color
                startX: root.radius
                PathArc {
                    relativeX: -root.radius
                    relativeY: root.radius
                    radiusX: root.radius
                    radiusY: radiusX
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    relativeX: 0
                    relativeY: -root.radius
                }
                PathLine {
                    relativeX: root.radius
                    relativeY: 0
                }
            }
        }
    }
}
