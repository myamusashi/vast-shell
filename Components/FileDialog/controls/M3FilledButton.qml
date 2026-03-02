import AnotherRipple
import QtQuick

import qs.Configs
import qs.Services
import qs.Components

Rectangle {
	id: root

    property string text: ""
    property bool enabled: true

    signal clicked

    implicitWidth: 96
    implicitHeight: 40
    radius: 20
    clip: true

    color: !enabled ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.12) : ma.pressed ? Qt.darker(Colours.m3Colors.m3Primary, 1.15) : ma.containsMouse ? Qt.lighter(Colours.m3Colors.m3Primary, 1.08) : Colours.m3Colors.m3Primary

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Elevation {
        anchors.fill: parent
        z: -1
        level: ma.containsMouse && enabled ? 3 : 1
        Behavior on level {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
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
        font.pixelSize: 14
        font.bold: true
        color: enabled ? Colours.m3Colors.m3OnPrimary : Qt.alpha(Colours.m3Colors.m3OnSurface, 0.38)
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
