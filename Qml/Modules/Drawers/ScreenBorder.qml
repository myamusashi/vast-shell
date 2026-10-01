import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services

Item {
    id: root

    anchors.fill: parent
    required property var window
    property alias border: border

    Scope {
        Exclusion {
            id: exclusiveLeft

            anchors.left: true

            property alias zone: exclusiveLeft.exclusiveZone

            screen: root.window.modelData
            name: "left"
            exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
        }
        Exclusion {
            id: exclusiveTop

            anchors.top: true

            property alias zone: exclusiveTop.exclusiveZone

            screen: root.window.modelData
            name: "top"
            exclusiveZone: {
                if (GlobalStates.isBarOpen) {
                    if (!Configs.generals.followFocusMonitor || root.window.modelData.name === Hypr.focusedMonitor.name)
                        return Configs.generals.outerBorderSize + Configs.bar.barHeight;
                    else {
                        if (Configs.generals.enableOuterBorder)
                            return Configs.generals.outerBorderSize;
                        else
                            return 0;
                    }
                } else
                    return Configs.generals.outerBorderSize;
            }
        }
        Exclusion {
            id: exclusiveRight

            anchors.right: true

            property alias zone: exclusiveRight.exclusiveZone

            screen: root.window.modelData
            name: "right"
            exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
        }
        Exclusion {
            id: exclusiveBottom

            anchors.bottom: true

            property alias zone: exclusiveBottom.exclusiveZone

            screen: root.window.modelData
            name: "bottom"
            exclusiveZone: Configs.generals.enableOuterBorder ? Configs.generals.outerBorderSize : 0
        }
    }

    Shape {
        id: border

        anchors.fill: parent

        property real borderTop: exclusiveTop.zone
        property real borderBottom: exclusiveBottom.zone
        property real borderLeft: exclusiveLeft.zone
        property real borderRight: exclusiveRight.zone
        property real innerRadius: 24

        readonly property color color: GlobalStates.drawerColors

        readonly property real holeW: width - borderLeft - borderRight
        readonly property real holeH: height - borderTop - borderBottom
        readonly property real r: Math.max(0, Math.min(innerRadius, holeW / 2, holeH / 2))
        z: -1

        Behavior on borderTop {
            NAnim {}
        }

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: border.color
            strokeColor: border.color
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill

            // Outer rectangle
            startX: 0
            startY: 0
            PathLine {
                x: border.width
                y: 0
            }
            PathLine {
                x: border.width
                y: border.height
            }
            PathLine {
                x: 0
                y: border.height
            }
            PathLine {
                x: 0
                y: 0
            }

            // Inner rounded rectangle
            PathMove {
                x: border.borderLeft + border.r
                y: border.borderTop
            }
            PathLine {
                x: border.width - border.borderRight - border.r
                y: border.borderTop
            }
            PathArc {
                x: border.width - border.borderRight
                y: border.borderTop + border.r
                radiusX: border.r
                radiusY: border.r
                direction: PathArc.Clockwise
            }
            PathLine {
                x: border.width - border.borderRight
                y: border.height - border.borderBottom - border.r
            }
            PathArc {
                x: border.width - border.borderRight - border.r
                y: border.height - border.borderBottom
                radiusX: border.r
                radiusY: border.r
                direction: PathArc.Clockwise
            }
            PathLine {
                x: border.borderLeft + border.r
                y: border.height - border.borderBottom
            }
            PathArc {
                x: border.borderLeft
                y: border.height - border.borderBottom - border.r
                radiusX: border.r
                radiusY: border.r
                direction: PathArc.Clockwise
            }
            PathLine {
                x: border.borderLeft
                y: border.borderTop + border.r
            }
            PathArc {
                x: border.borderLeft + border.r
                y: border.borderTop
                radiusX: border.r
                radiusY: border.r
                direction: PathArc.Clockwise
            }
        }
    }

    component Exclusion: PanelWindow { // qmllint disable
        property string name
        implicitWidth: 0
        implicitHeight: 0
        WlrLayershell.namespace: `quickshell:${name}ExclusionZone`
    }
}
