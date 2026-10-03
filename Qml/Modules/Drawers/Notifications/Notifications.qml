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

    edge: Qt.TopEdge
    alignment: Qt.AlignRight
    open: Notifs.popups.length > 0
    depth: open ? Math.min(notifListView.contentHeight + 30, parent.height * 0.5) : 0
    length: Math.min(Math.round(parent.width * 0.22), 360)
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    ListView {
        id: notifListView

        anchors.fill: parent
        spacing: Appearance.spacing.normal
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        model: ScriptModel {
            values: [...Notifs.popups]
        }

        cacheBuffer: implicitHeight

        delegate: Wrapper {
            required property var modelData
            required property int index

            isPopup: true
            notif: modelData
        }
    }
}
