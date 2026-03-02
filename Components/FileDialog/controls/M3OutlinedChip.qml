import AnotherRipple
import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Services
import qs.Components

Rectangle {
	id: root

    property string text: ""

    radius: 8
    color: ma.containsMouse ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08) : "transparent"
    border.color: Colours.m3Colors.m3Outline
    border.width: 1
    clip: true

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 8
        color: Colours.m3Colors.m3OnSurface
        acceptEvent: false
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 8
        }
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: 12
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
        }

        StyledText {
            text: "▾"
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: 11
        }
    }

    MouseArea {
		id: ma

        anchors.fill: parent
        hoverEnabled: true
    }
}
