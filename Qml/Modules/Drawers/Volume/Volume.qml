pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    required property Drawer session      // the drawer this one sits beside

    readonly property bool shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isOSDVisible("volume") // qmllint disable

    edge: Qt.RightEdge
    open: shown
    edgeOffset: session.width
    depth: 60 + (Volume.openPerAppVolume && loader.item ? loader.item.perAppWidth + Volume.itemSpacing : 0) // qmllint disable
    length: 280
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    Loader {
        id: loader

        anchors.fill: parent
        active: root.shown
        asynchronous: true
        onActiveChanged: {
            if (!active)
                Volume.openPerAppVolume = false;
        }

        sourceComponent: Content {
            controller: Volume
            linkTracker: Volume.linkTracker
        }
    }
}
