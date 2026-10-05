import QtQuick
import Quickshell.Services.Notifications

import qs.Components.Feedback
import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils as H
import qs.Services

Item {
    id: root

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    property bool isPopup: false
    property alias mouseArea: delegateMouseNotif
    required property var notif
    property real timerDuration: 3000
    property real timerRemaining: timerDuration
    property real timerStartTime: 0

    signal entered
    signal exited

    function pauseTimer() {
        if (timer.running) {
            timerRemaining = Math.max(0, timerRemaining - (Date.now() - timerStartTime));
            timer.stop();
        }
        if (borderAnimation.animation.running)
            borderAnimation.animation.pause();
    }
    function resetTimer() {
        timerRemaining = timerDuration;
        timer.interval = timerDuration;
        timerStartTime = Date.now();
        timer.restart();
        borderAnimation.animation.restart();
    }
    function resumeTimer() {
        if (!timer.running && timerRemaining > 0) {
            timer.interval = timerRemaining;
            timerStartTime = Date.now();
            timer.start();
        }
        if (borderAnimation.animation.paused)
            borderAnimation.animation.resume();
    }

    clip: true
    implicitHeight: innerRow.implicitHeight + 20
    implicitWidth: parent.width
    x: parent.width

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }
    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.emphasized
            easing.bezierCurve: Appearance.animations.curves.emphasized
        }
    }

    Component.onCompleted: {
        slideInAnim.start();
        timerStartTime = Date.now();
        timer.start();
    }
    Component.onDestruction: {
        slideInAnim.stop();
        slideOutAnim.stop();
        swipeOutAnim.stop();
    }
    ListView.onPooled: {
        slideInAnim.stop();
        slideOutAnim.stop();
        borderAnimation.animation.stop();
    }
    ListView.onReused: {
        x = parent.width;
        slideInAnim.start();
        resetTimer();
    }

    Timer {
        id: timer

        interval: root.timerDuration

        onTriggered: slideOutAnim.start()
    }
    NAnim {
        id: slideInAnim

        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
        from: root.parent.width
        property: "x"
        target: root
        to: 0

        onFinished: borderAnimation.animation.start()
    }
    NAnim {
        id: slideOutAnim

        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        property: "x"
        target: root
        to: root.parent.width

        onFinished: {
            if (root.isPopup)
                root.notif.popup = false;
            root.notif.unlock(root);
        }
    }
    NAnim {
        id: swipeOutAnim

        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.standardAccel
        property: "x"
        target: root

        onFinished: {
            root.notif.unlock(root);
            root.notif.close();
        }
    }
    StyledRect {
        id: wrapperRect

        color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer
        radius: Appearance.rounding.normal

        anchors {
            fill: parent
            leftMargin: 10
        }
        HoverHandler {
            id: notifHover
        }
        Connections {
            function onHoveredChanged() {
                if (notifHover.hovered) {
                    root.pauseTimer();
                } else if (!delegateMouseNotif.pressed && !delegateMouseNotif.drag.active) {
                    root.resumeTimer();
                }
            }

            target: notifHover
        }
        Connections {
            function onReplyFocusedChanged() {
                if (contentLayout.replyFocused)
                    root.pauseTimer();
                else if (!notifHover.hovered && !delegateMouseNotif.pressed && !delegateMouseNotif.drag.active)
                    root.resumeTimer();
            }

            target: contentLayout
        }
        H.MArea {
            id: delegateMouseNotif

            onPressed: root.pauseTimer()
            onReleased: {
                if (!notifHover.hovered && !drag.active)
                    root.resumeTimer();
            }

            drag {
                axis: Drag.XAxis
                maximumX: root.width
                minimumX: -root.width
                target: root

                onActiveChanged: {
                    if (drag.active) {
                        root.pauseTimer();
                        return;
                    }
                    if (Math.abs(root.x) > root.width * 0.45) {
                        swipeOutAnim.to = root.x > 0 ? root.width : -root.width;
                        swipeOutAnim.start();
                    } else {
                        root.x = 0;
                        if (!notifHover.hovered)
                            root.resumeTimer();
                    }
                }
            }
        }
        Row {
            id: innerRow

            spacing: Appearance.spacing.normal

            anchors {
                left: parent.left
                leftMargin: Appearance.margin.small
                right: parent.right
                rightMargin: Appearance.margin.small
                top: parent.top
                topMargin: Appearance.margin.small
            }
            NotifIcon {
                id: iconLayout

                modelData: root.notif
            }
            Content {
                id: contentLayout

                modelData: root.notif
                width: parent.width - iconLayout.width - parent.spacing
            }
        }
    }
    Rectangle {
        anchors.fill: wrapperRect
        color: "transparent"
        radius: wrapperRect.radius

        border {
            color: Colours.m3Colors.m3OutlineVariant
            width: 2.0
        }
    }
    BorderProgress {
        id: borderAnimation

        anchors.fill: wrapperRect
        animationDuration: root.timerDuration
        borderColor: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary
        borderWidth: 2.0
        progress: 1.0
        radius: wrapperRect.radius
        source: wrapperRect
    }
}
