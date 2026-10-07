import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    property bool capsLockOn: false

    activeFocusOnTab: false
    focus: false
    implicitHeight: popupContent.implicitHeight + Appearance.margin.large * 2
    implicitWidth: popupContent.implicitWidth + Appearance.margin.large * 2
    opacity: 0
    scale: 0.92
    visible: opacity > 0
    Behavior on opacity {
        NAnim {
            duration: Appearance.animations.durations.normal
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }
    Behavior on scale {
        NAnim {
            duration: Appearance.animations.durations.normal
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    StyledRect {
        anchors.fill: parent
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1
        color: Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.large

        Elevation {
            anchors.fill: parent
            level: 3
            radius: parent.radius
        }

        Row {
            id: popupContent

            anchors.centerIn: parent
            spacing: Appearance.spacing.normal

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.Medium
                text: qsTr("Caps Lock")
            }

            Icon {
                color: root.capsLockOn ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.extraLarge
                icon: root.capsLockOn ? "lock" : "lock_open_right"
            }
        }
    }

    Timer {
        id: capslockPopupTimer

        interval: 2000
        repeat: false
        onTriggered: {
            root.opacity = 0;
            root.scale   = 0.92;
        }
    }

    Connections {
        function onCapsLockChanged() {
            root.capsLockOn = KeylockState.capsLock;
            root.opacity    = 1;
            root.scale      = 1;
            capslockPopupTimer.restart();
        }

        target: KeylockState
    }
}
