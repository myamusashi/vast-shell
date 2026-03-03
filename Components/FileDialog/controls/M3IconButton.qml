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
    color: toggled ? Colours.m3Colors.m3SecondaryContainer : "transparent"
    opacity: enabled ? 1.0 : 0.38

    Behavior on color {
        CAnim {
            duration: Appearance.animations.durations.small
        }
    }

    Icon {
        id: iconItem
        anchors.centerIn: parent
        icon: root.icon
        font.pixelSize: Appearance.fonts.size.large
        rotation: root.spinAngle
        color: root.toggled ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface

        Behavior on color {
            CAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    SimpleRipple {
        anchors.fill: parent
        clipRadius: 20
        color: root.toggled ? Colours.m3Colors.m3OnSecondaryContainer : Colours.m3Colors.m3OnSurface
        acceptEvent: false
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled

        onEntered: {
            if (!root.toggled)
                root.color = Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08);
        }
        onExited: {
            if (!root.toggled)
                root.color = "transparent";
        }
        onPressed: root.color = Qt.alpha(Colours.m3Colors.m3OnSurface, 0.12)
        onReleased: root.color = Qt.alpha(Colours.m3Colors.m3OnSurface, 0.08)

        onClicked: {
            if (root.spinOnClick)
                root.spinAngle += 360;

            root.clicked();
        }
    }
}
