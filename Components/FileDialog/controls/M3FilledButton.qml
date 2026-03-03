pragma ComponentBehavior: Bound

import AnotherRipple
import QtQuick

import qs.Configs
import qs.Services
import qs.Components

Rectangle {
    id: root

    property string text: ""

    signal clicked

    implicitWidth: 96
    implicitHeight: 48
    radius: height / 2
    clip: true

    color: !enabled ? Colours.m3Colors.m3Primary : ma.pressed ? Colours.m3Colors.m3Primary : ma.containsMouse ? Qt.alpha(Colours.m3Colors.m3OnPrimary, 0.08) : Colours.m3Colors.m3Primary

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
	}

	Elevation {
		anchors.fill: parent
		z: -1
		radius: parent.radius
		level: ma.containsMouse ? 1 : 0
	}

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 20
        color: Colours.m3Colors.m3OnPrimary
        acceptEvent: false
    }

    StyledText {
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Appearance.fonts.size.normal
        font.bold: true
        color: Colours.m3Colors.m3OnPrimary
        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    MouseArea {
        id: ma

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
