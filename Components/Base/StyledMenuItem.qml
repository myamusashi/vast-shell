import AnotherRipple
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

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

            color: trailingIconItem.icon === "" ? "transparent" : Colours.m3Colors.m3SurfaceContainerHighest

            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    contentItem: RowLayout {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight

        StyledText {
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: Appearance.margin.normal

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

        Item {
            Layout.alignment: Qt.AlignCenter
            implicitWidth: 30
            implicitHeight: 30

            Icon {
                anchors.centerIn: parent
                icon: "check_box_outline_blank"
                font.pixelSize: Appearance.fonts.size.large
                color: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant

                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                        easing.bezierCurve: Appearance.animations.curves.standard
                    }
                }
            }

            Icon {
                id: trailingIconItem

                anchors.centerIn: parent
                icon: ""
                font.pixelSize: Appearance.fonts.size.large
                color: root.highlighted ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
                visible: root.trailingIcon !== ""

                Behavior on color {
                    CAnim {
                        duration: Appearance.animations.durations.small
                        easing.bezierCurve: Appearance.animations.curves.standard
                    }
                }
            }
        }
    }

    SimpleRipple {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.small
            rightMargin: Appearance.margin.small
        }
        color: Colours.m3Colors.m3OnSurface
        xClipRadius: Appearance.rounding.normal
        yClipRadius: Appearance.rounding.normal
    }
}
