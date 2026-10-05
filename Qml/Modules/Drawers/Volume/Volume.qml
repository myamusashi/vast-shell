pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Drawer {
    id: root

    required property Drawer session
    readonly property bool shown: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && GlobalStates.isOSDVisible("volume") // qmllint disable

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: 60 + (Volume.openPerAppVolume && loader.item ? loader.item.perAppWidth + Volume.itemSpacing : 0) // qmllint disable
    edge: Qt.RightEdge
    edgeOffset: session.width
    filletRadius: 40
    length: 280
    open: shown

    Loader {
        id: loader

        active: root.shown
        anchors.fill: parent
        asynchronous: true

        sourceComponent: Content {
            controller: Volume
            linkTracker: Volume.linkTracker
        }

        onActiveChanged: {
            if (!active)
                Volume.openPerAppVolume = false;
        }
    }
}
