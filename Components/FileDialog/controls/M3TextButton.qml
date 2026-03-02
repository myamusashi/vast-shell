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
    color: ma.pressed ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : ma.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent"
    opacity: enabled ? 1.0 : 0.38

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 20
        color: Colours.m3Colors.m3Primary
        acceptEvent: false
    }

    StyledText {
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 14
        font.bold: true
        color: Colours.m3Colors.m3Primary
    }

    MouseArea {
		id: ma

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
