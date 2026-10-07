pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Components.Base.DrawerComponents
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "Components"

Drawer {
    id: root

    alignment: Qt.AlignRight
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: open ? Math.min(notifListView.contentHeight + 30, parent.height * 0.5) : 0
    edge: Qt.TopEdge
    filletRadius: 40
    length: Math.min(Math.round(parent.width * 0.22), 360)
    open: Notifs.popups.length > 0

    ListView {
        id: notifListView

        anchors.fill: parent
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: implicitHeight
        clip: true
        spacing: Appearance.spacing.normal
        delegate: Wrapper {
            required property int index
            required property var modelData

            isPopup: true
            notif: modelData
        }
        model: ScriptModel {
            values: [...Notifs.popups]
        }
    }
}
