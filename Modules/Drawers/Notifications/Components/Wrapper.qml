import QtQuick
import Quickshell.Services.Notifications

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils as H
import qs.Services

Item {
    id: root

    property alias contentLayout: contentLayout
    property alias iconLayout: iconLayout
    property alias mArea: delegateMouseNotif

    required property var notif

    property bool isPopup: false
    property real _timerDuration: 3000
    property real _timerStartTime: 0
    property real _timerRemaining: _timerDuration

    signal entered
    signal exited

    implicitWidth: parent.width
    implicitHeight: innerRow.implicitHeight + 20
    clip: true
    x: parent.width

    function pauseTimer() {
        if (timer.running) {
            _timerRemaining = Math.max(0, _timerRemaining - (Date.now() - _timerStartTime));
            timer.stop();
        }
        if (borderAnim.running)
            borderAnim.pause();
    }

    function resumeTimer() {
        if (!timer.running && _timerRemaining > 0) {
            timer.interval = _timerRemaining;
            _timerStartTime = Date.now();
            timer.start();
        }
        if (borderAnim.paused)
            borderAnim.resume();
    }

    function resetTimer() {
        _timerRemaining = _timerDuration;
        timer.interval = _timerDuration;
        _timerStartTime = Date.now();
        timer.restart();
        borderAnim.restart();
    }

    Timer {
        id: timer

        interval: root._timerDuration
        onTriggered: slideOutAnim.start()
    }

    Component.onCompleted: {
        slideInAnim.start();
        _timerStartTime = Date.now();
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
        borderAnim.stop();
    }

    ListView.onReused: {
        x = parent.width;
        slideInAnim.start();
        resetTimer();
    }

    NAnim {
        id: slideInAnim

        target: root
        property: "x"
        from: root.parent.width
        to: 0
        duration: Appearance.animations.durations.emphasized
        easing.bezierCurve: Appearance.animations.curves.emphasized
        onFinished: borderAnim.start()
    }

    NAnim {
        id: slideOutAnim

        target: root
        property: "x"
        to: root.parent.width
        duration: Appearance.animations.durations.emphasizedAccel
        easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
        onFinished: {
            if (root.isPopup)
                root.notif.popup = false;
            root.notif.unlock(root);
        }
    }

    NAnim {
        id: swipeOutAnim

        target: root
        property: "x"
        duration: Appearance.animations.durations.small
        easing.bezierCurve: Appearance.animations.curves.standardAccel
        onFinished: {
            root.notif.unlock(root);
            root.notif.close();
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

    StyledRect {
        id: wrapperRect

        anchors {
            fill: parent
            leftMargin: 10
        }
        radius: Appearance.rounding.normal
        color: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3ErrorContainer : Colours.m3Colors.m3SurfaceContainer
        layer.enabled: borderFx.visible

        HoverHandler {
            id: notifHover
        }

        Connections {
            target: notifHover

            function onHoveredChanged() {
                if (notifHover.hovered) {
                    root.pauseTimer();
                } else if (!delegateMouseNotif.pressed && !delegateMouseNotif.drag.active) {
                    root.resumeTimer();
                }
            }
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
                target: root
                minimumX: -root.width
                maximumX: root.width

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

            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: Appearance.margin.small
                leftMargin: Appearance.margin.small
                rightMargin: Appearance.margin.small
            }
            spacing: Appearance.spacing.normal

            Icon {
                id: iconLayout

                modelData: root.notif
            }

            Content {
                id: contentLayout

                width: parent.width - iconLayout.width - parent.spacing
                modelData: root.notif
            }
        }
    }

    ShaderEffect {
        id: borderFx

        anchors {
            fill: wrapperRect
        }

        z: 999
        property var source: wrapperRect
        property real progress: 1.0
        property real radius: wrapperRect.radius
        property real borderWidth: 2.0
        property vector2d resolution: Qt.vector2d(wrapperRect.width, wrapperRect.height)
        property color borderColor: root.notif.urgency === NotificationUrgency.Critical ? Colours.m3Colors.m3Error : Colours.m3Colors.m3Primary

        vertexShader: "root:/Assets/shaders/borderProgress.vert.qsb"
        fragmentShader: "root:/Assets/shaders/borderProgress.frag.qsb"
    }

    NumberAnimation {
        id: borderAnim

        target: borderFx
        property: "progress"
        from: 1.0
        to: 0.0
        duration: root._timerDuration
        onFinished: borderFx.destroy()
    }
}
