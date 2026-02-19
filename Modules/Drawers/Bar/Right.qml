pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Widgets as Wid

RowLayout {
    layoutDirection: Qt.RightToLeft
    spacing: Appearance.spacing.normal

    Wid.Clock {}
    Wid.NotificationDots {
        implicitHeight: parent.height
    }
    Wid.Tray {}
    Wid.Battery {
        widthBattery: 36
        heightBattery: 18
    }
    Wid.Sound {}
}
