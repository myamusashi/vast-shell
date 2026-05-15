import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Rectangle {
    id: root

    property alias text: textItem.text
    property alias iconName: iconItem.icon
    property int pageIndex: 0
    property bool isActive: pageIndex === settingsLoader.currentPage

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    radius: height / 2
    color: isActive ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    Behavior on color {
        CAnim {}
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.large
            rightMargin: Appearance.margin.large
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem

            font.pixelSize: Appearance.fonts.size.extraLarge
            color: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            layer.enabled: true
            layer.smooth: true

            font.variableAxes: {
                "FILL": (area.containsPress || root.isActive) ? 1 : 0
            }

            rotation: area.containsPress ? 25 : area.containsMouse ? 15 : root.isActive ? 20 : 0

            transform: Rotation {
                id: flipRotation
                origin.x: iconItem.width / 2
                origin.y: iconItem.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: 0
            }

            states: State {
                name: "flipped"
                when: area.containsPress
                PropertyChanges {
                    target: flipRotation
                    angle: 180
                }
            }

            transitions: Transition {
                NAnim {
                    target: flipRotation
                    property: "angle"
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }

            Behavior on color {
                CAnim {}
            }

            Behavior on rotation {
                NAnim {
                    duration: Appearance.animations.durations.normal
                }
            }
        }

        StyledText {
            id: textItem

            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isActive
            color: root.isActive ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            Behavior on color {
                CAnim {}
            }
        }
    }

    MArea {
        id: area

        layerColor: "transparent"
        layerRadius: root.radius
        anchors.fill: parent
        onClicked: settingsLoader.currentPage = root.pageIndex

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: area.containsMouse && !root.isActive ? Qt.rgba(Colours.m3Colors.m3OnSurface.r, Colours.m3Colors.m3OnSurface.g, Colours.m3Colors.m3OnSurface.b, 0.08) : "transparent"
            Behavior on color {
                CAnim {}
            }
        }
    }
}
