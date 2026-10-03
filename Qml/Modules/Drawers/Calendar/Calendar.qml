pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils

Drawer {
    id: container

    edge: Qt.TopEdge
    alignment: Qt.AlignRight
    open: GlobalStates.isCalendarOpen
    depth: 300
    length: parent.width * 0.2
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    Loader {
        id: contentLoader

        anchors.fill: parent
        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && container.isCalendarShow // qmllint disable
        asynchronous: true
        sourceComponent: Content {}
    }
}
