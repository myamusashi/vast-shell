pragma ComponentBehavior: Bound

import QtQuick

import qs.Configs
import qs.Helpers
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

    color: !enabled ? Qt.alpha(Colours.m3Colors.m3OnSurface, 0.12) : ma.pressed ? Qt.tint(Colours.m3Colors.m3Primary, Qt.alpha(Colours.m3Colors.m3OnPrimary, 0.12)) : ma.containsMouse ? Qt.tint(Colours.m3Colors.m3Primary, Qt.alpha(Colours.m3Colors.m3OnPrimary, 0.08)) : Colours.m3Colors.m3Primary

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    StyledText {
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Appearance.fonts.size.normal
        font.bold: true
        color: !enabled ? Colours.m3Colors.m3OnSurfaceVariant : Colours.m3Colors.m3OnPrimary
        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    MArea {
        id: ma

        layerRadius: root.radius
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
