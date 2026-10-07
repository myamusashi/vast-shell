pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils

Drawer {
    id: container

    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: 300
    edge: Qt.TopEdge
    filletRadius: 40
    length: parent.width * 0.2
    open: GlobalStates.isCalendarOpen

    Loader {
        id: contentLoader

        active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && container.isCalendarShow // qmllint disable
        anchors.fill: parent
        asynchronous: true
        sourceComponent: Content {}
    }
}
