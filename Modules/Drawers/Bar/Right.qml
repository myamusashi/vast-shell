pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Helpers
import qs.Widgets as Wid
import qs.Services
import qs.Components

RowLayout {
    anchors.margins: 5
    layoutDirection: Qt.RightToLeft
    spacing: Appearance.spacing.small

    clip: true
    Wid.Clock {}
    Wid.Tray {}
    StyledRect {
        color: Colours.m3Colors.m3SurfaceContainer
        clip: true
        radius: Appearance.rounding.normal
        implicitWidth: quickSettingsLayout.childrenRect.width
        implicitHeight: parent.height * 0.7

        Row {
            id: quickSettingsLayout

            anchors {
                fill: parent
                horizontalCenter: parent.horizontalCenter
            }
            spacing: Appearance.spacing.normal

            Wid.Sound {
                implicitHeight: parent.height
            }

            Wid.Battery {
                implicitHeight: parent.height
                implicitWidth: 20
                widthBattery: 36
                heightBattery: 18
            }

            Wid.NotificationDots {
                implicitWidth: 50
                implicitHeight: parent.height
            }
        }

        MArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen
        }
    }
}
