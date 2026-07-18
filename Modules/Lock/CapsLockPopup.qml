import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

Item {
    id: root

    visible: opacity > 0
    opacity: 0
    scale: 0.92
    focus: false
    activeFocusOnTab: false

    property bool capsLockOn: false

    implicitWidth: popupContent.implicitWidth + Appearance.margin.large * 2
    implicitHeight: popupContent.implicitHeight + Appearance.margin.large * 2

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
        radius: Appearance.rounding.large
        color: Colours.m3Colors.m3SurfaceContainer
        border.color: Colours.m3Colors.m3OutlineVariant
        border.width: 1

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
                text: qsTr("Caps Lock")
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.weight: Font.Medium
            }

            Icon {
                icon: root.capsLockOn ? "lock" : "lock_open_right"
                color: root.capsLockOn ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3Tertiary
                font.pixelSize: Appearance.fonts.size.extraLarge
            }
        }
    }

    Timer {
        id: capslockPopupTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.opacity = 0;
            root.scale = 0.92;
        }
    }

    Connections {
        target: KeylockState

        function onCapsLockChanged() {
            root.capsLockOn = KeylockState.capsLock;
            root.opacity = 1;
            root.scale = 1;
            capslockPopupTimer.restart();
        }
    }
}
