import AnotherRipple
import QtQuick

import qs.Configs
import qs.Services
import qs.Components
import qs.Helpers

Rectangle {
    id: root

    property string icon: ""
    property bool enabled: true
    property bool toggled: false
    property bool spinOnClick: false
    property real spinAngle: 0

    signal clicked

    implicitWidth: 40
    implicitHeight: 40
    radius: height / 2
    clip: true
    color: toggled ? Colours.m3Colors.m3Primary : "transparent"
    opacity: enabled ? 1.0 : 0.38

    Behavior on color {
        CAnim {}
    }

    Icon {
        id: iconItem

        anchors.centerIn: parent
        icon: root.icon
        font.pixelSize: Appearance.fonts.size.large
        rotation: root.spinAngle
        color: root.toggled ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3OnSurface
        opacity: root.toggled ? 1.0 : 0.38

        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    MArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        layerRadius: Appearance.rounding.full
        onClicked: {
            if (root.spinOnClick)
                root.spinAngle += 360;

            root.clicked();
        }
    }
}
