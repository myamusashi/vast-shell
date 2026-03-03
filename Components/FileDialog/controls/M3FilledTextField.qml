import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components
import qs.Helpers

Rectangle {
    id: root

    property string text: ""
    property string prefixIcon: ""

    signal accepted(string text)

    height: 48
    radius: Appearance.rounding.small
    color: Colours.m3Colors.m3SurfaceContainerHighest

    // Active indicator line
    Rectangle {
        id: indicator

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: input.activeFocus ? 2 : 1
        width: input.activeFocus ? parent.width : parent.width - 4
        color: input.activeFocus ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurfaceVariant

        Behavior on width {
            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
            }
        }
        Behavior on height {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.margin.larger
        anchors.rightMargin: Appearance.margin.smaller
        spacing: Appearance.spacing.small

        Icon {
            id: prefixIconItem
            visible: root.prefixIcon !== ""
            icon: root.prefixIcon
            font.pixelSize: Appearance.fonts.size.medium
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: root.text
            onAccepted: root.accepted(text)
        }
    }
}
