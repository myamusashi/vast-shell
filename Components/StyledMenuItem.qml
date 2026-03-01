import QtQuick
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

MenuItem {
    id: root

    property alias trailingIcon: trailingIconItem.icon

    implicitWidth: 200
    implicitHeight: 48

    background: Rectangle {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        radius: Appearance.rounding.normal
        color: root.highlighted ? Colours.m3Colors.m3SecondaryContainer : "transparent"

        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.standard
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: {
                const c = Qt.color(Colours.m3Colors.m3OnSurface);
                if (root.pressed)
                    return Qt.rgba(c.r, c.g, c.b, 0.12);
                if (root.hovered)
                    return Qt.rgba(c.r, c.g, c.b, 0.08);
                return "transparent";
            }

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    contentItem: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        StyledText {
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: Appearance.margin.normal
                right: trailingIconItem.visible ? trailingIconItem.left : parent.right
                rightMargin: Appearance.margin.normal
            }

            text: root.text
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Medium
            font.letterSpacing: 0.15
            elide: StyledText.ElideRight
            verticalAlignment: StyledText.AlignVCenter

            color: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        Icon {
            id: trailingIconItem

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Appearance.margin.normal
            }

            icon: ""
            font.pixelSize: Appearance.fonts.size.large
            visible: root.trailingIcon !== ""

            color: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                    easing.bezierCurve: Appearance.animations.curves.standard
                }
            }
        }
    }
}
