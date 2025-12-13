import QtQuick
import Quickshell.Services.Notifications

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

Item {
    id: root

    required property var notif
    property bool isRemoving: false
    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    property alias mArea: delegateMouseNotif

    signal entered
    signal exited
    signal animationCompleted

    implicitWidth: isRemoving ? 0 : parent.width
    implicitHeight: isRemoving ? 0 : contentLayout.height * 1.3
    clip: true
    x: parent.width

    Component.onCompleted: slideInAnim.start()

    Component.onDestruction: {
        slideInAnim.stop();
        slideOutAnim.stop();
        swipeOutAnim.stop();
    }

    ListView.onPooled: {
        slideInAnim.stop();
        slideOutAnim.stop();
    }

    ListView.onReused: {
        isRemoving = false;
        x = parent.width;
        slideInAnim.start();
    }

    NAnim {
        id: slideInAnim

        target: root
        property: "x"
        from: root.parent.width
        to: 0
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
        onFinished: root.animationCompleted()
    }

    NAnim {
        id: slideOutAnim

        target: root
        property: "x"
        to: root.parent.width
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        onFinished: root.isRemoving = true
    }

    NAnim {
        id: swipeOutAnim

        target: root
        property: "x"
        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.standardAccel
        onFinished: {
            root.notif.popup = false;
            if (root.notif)
                root.notif.close();
        }
    }

    Behavior on x {
        enabled: !root.isRemoving && !delegateMouseNotif.drag.active
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    function removeNotificationWithAnimation() {
        slideOutAnim.start();
    }

    StyledRect {
        anchors {
            fill: parent
            leftMargin: 10
        }
        radius: Appearance.rounding.normal
        clip: true

        color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer

        border {
            color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : "transparent"
            width: root.notif.urgency === NotificationUrgency.Critical ? 1 : 0
        }

        MArea {
            id: delegateMouseNotif

            anchors.fill: parent
            hoverEnabled: true

            onEntered: root.entered()
            onExited: root.exited()

            drag {
                axis: Drag.XAxis
                target: root
                minimumX: -root.width
                maximumX: root.width

                onActiveChanged: {
                    if (drag.active)
                        return;
                    if (Math.abs(root.x) > root.width * 0.45) {
                        swipeOutAnim.to = root.x > 0 ? root.width : -root.width;
                        swipeOutAnim.start();
                    } else {
                        root.x = 0;
                    }
                }
            }
        }

        Row {
            anchors {
                fill: parent
                topMargin: 10
                leftMargin: 10
                rightMargin: 10
            }
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: root.notif
            }

            Content {
                id: contentLayout

                modelData: root.notif
            }
        }
    }
}
