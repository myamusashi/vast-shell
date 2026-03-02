import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

Rectangle {
    id: root

    property string text: ""
    property string prefixIcon: ""

    signal accepted(string text)

    height: 40
    radius: 4
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
        anchors.leftMargin: 12
        anchors.rightMargin: 8
        spacing: 6

        StyledText {
            visible: root.prefixIcon !== ""
            text: root.prefixIcon
            font.pixelSize: 14
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            verticalAlignment: TextInput.AlignVCenter
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: 13
            text: root.text
            onAccepted: root.accepted(text)
        }
    }
}
