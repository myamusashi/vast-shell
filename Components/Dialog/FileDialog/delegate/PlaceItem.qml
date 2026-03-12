import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Core.Utils
import qs.Services
import qs.Components.Base

Rectangle {
    id: root

    required property string icon
    required property string label
    required property bool isSelected

    signal clicked

    implicitHeight: 48
    radius: Appearance.rounding.small
    clip: true
    color: isSelected ? Colours.m3Colors.m3SecondaryContainer : "transparent"

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: Appearance.margin.normal
            rightMargin: Appearance.margin.small
        }
        spacing: Appearance.spacing.normal

        Icon {
            id: iconItem
            icon: root.icon
            font.pixelSize: Appearance.fonts.size.large
            color: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }

        StyledText {
            id: label

            text: root.label
            color: root.isSelected ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            font.bold: root.isSelected
            Layout.fillWidth: true
            elide: Text.ElideRight
            Behavior on color {
                CAnim {
                    duration: Appearance.animations.durations.small
                }
            }
        }
    }

    MArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
