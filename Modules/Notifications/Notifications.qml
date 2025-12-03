pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.Configs
import qs.Services
import qs.Components

import "Components" as Com

StyledRect {
    id: container

    anchors {
        right: parent.right
        top: parent.top
        rightMargin: 5
        topMargin: 5
    }

    property bool hasNotifications: Notifs.notifications.popupNotifications.length > 0

    width: 400
    height: hasNotifications ? Math.min(notifColumn.height + 30, parent.height * 0.4) : 0
    color: Themes.m3Colors.m3Background
    radius: 0
    clip: true
    bottomLeftRadius: Appearance.rounding.normal

    Behavior on width {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Flickable {
        id: notifFlickable

        anchors.fill: container
        contentHeight: notifColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: notifColumn

            width: parent.width
            spacing: Appearance.spacing.normal

            Repeater {
                id: notifRepeater

                model: ScriptModel {
                    values: [...Notifs.notifications.popupNotifications.map(a => a)].reverse()
                }

                delegate: Com.Wrapper {
                    id: wrapper

                    onEntered: closePopups.stop()
                    onExited: closePopups.start()

                    Timer {
                        id: closePopups

                        interval: wrapper.modelData.urgency === NotificationUrgency.Critical ? 10000 : 5000
                        running: true
                        onTriggered: wrapper.removeNotificationWithAnimation()
                    }

                    Timer {
                        id: removeTimer
                        interval: Appearance.animations.durations.emphasizedAccel + 50
                        onTriggered: Notifs.notifications.removePopupNotification(wrapper.modelData)
                    }
                }
            }
        }
    }
}
