import QtQuick

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

Rectangle {
    id: root

    property alias text: text.text
    property bool enabled: true

    signal clicked

    implicitWidth: 96
    implicitHeight: 48
    radius: height / 2
    clip: true
    color: ma.pressed ? Qt.alpha(Colours.m3Colors.m3Primary, 0.12) : ma.containsMouse ? Qt.alpha(Colours.m3Colors.m3Primary, 0.08) : "transparent"
    opacity: enabled ? 1.0 : 0.38

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    StyledText {
        id: text

        anchors.centerIn: parent
        font.pixelSize: Appearance.fonts.size.normal
        font.bold: true
        color: Colours.m3Colors.m3Primary
    }

    MArea {
        id: ma

        layerRadius: root.radius
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
