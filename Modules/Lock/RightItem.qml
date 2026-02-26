import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components
import qs.Modules.Drawers.QuickSettings.Settings

Item {
    anchors {
        right: parent.right
        verticalCenter: parent.verticalCenter
    }

    property alias leftCorner: bottomLeftCorner
    property alias rightCorner: topLeftCorner
    required property bool isLockscreenOpen

    implicitWidth: 0
    implicitHeight: isLockscreenOpen ? parent.height * 0.7 : 0

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        id: bottomLeftCorner

        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: 0
        color: GlobalStates.drawerColors
    }

    Corner {
        id: topLeftCorner

        location: Qt.TopRightCorner
        extensionSide: Qt.Vertical
        radius: 0
        color: GlobalStates.drawerColors
    }

    Notifications {
        anchors.fill: parent

        radius: 0
        topLeftRadius: Appearance.rounding.normal
        bottomLeftRadius: Appearance.rounding.normal
        color: GlobalStates.drawerColors

        loader.active: GlobalStates.isLockscreenOpen
    }
}
