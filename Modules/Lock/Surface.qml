pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Wayland

import qs.Data
import qs.Components

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    Connections {
        target: root.lock

        function onUnlock(): void {
            unlockSequence.start();
        }
    }

    StyledRect {
        id: surface

        anchors.fill: parent
        color: Colors.colors.surface_container_lowest

        ScreencopyView {
            id: wallpaper

            anchors.fill: parent
            captureSource: root.screen
            opacity: 1
            visible: true
        }

        MultiEffect {
            id: wallEffect

            source: wallpaper
            anchors.fill: parent
            blurEnabled: true
            blurMax: 64
            blur: 1.0
        }

        ColumnLayout {
            id: clockContainer

            anchors {
                centerIn: parent
                verticalCenterOffset: -80
            }
            spacing: Appearance.spacing.normal
            opacity: 0
            scale: 0.8

            Clock {}
        }

        ColumnLayout {
            id: inputContainer

            spacing: Appearance.spacing.larger
            opacity: 0
            scale: 0.95

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Appearance.spacing.large * 4
            }

            InputField {
                pam: root.pam
            }
        }

        ColumnLayout {
            id: sessionContainer

            spacing: Appearance.spacing.normal
            opacity: 0
            scale: 0.8

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: Appearance.spacing.large
            }

            SessionButton {}
        }
    }

    SequentialAnimation {
        id: unlockSequence

        ParallelAnimation {
            OpacityAnimator {
                target: wallEffect
                from: 1
                to: 0
                easing.bezierCurve: Appearance.animations.curves.standardDecel
                duration: Appearance.animations.durations.extraLarge
            }

            PropertyAnimation {
                target: clockContainer
                properties: "opacity,scale"
                from: 1
                to: 0
                duration: Appearance.animations.durations.expressiveFastSpatial
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }

            PropertyAnimation {
                target: inputContainer
                properties: "opacity,scale"
                from: 1
                to: 0
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }

            PropertyAnimation {
                target: sessionContainer
                properties: "opacity,scale"
                from: 1
                to: 0
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.emphasizedAccel
            }
        }

        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    SequentialAnimation {
        id: entrySequence

        running: true

        ParallelAnimation {
            OpacityAnimator {
                target: wallEffect
                from: 0
                to: 1
                easing.bezierCurve: Appearance.animations.curves.standardAccel
                duration: Appearance.animations.durations.large
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: Appearance.animations.durations.small
                }

                PropertyAnimation {
                    target: clockContainer
                    properties: "opacity,scale"
                    from: 0
                    to: 1
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                }

                PropertyAnimation {
                    target: inputContainer
                    properties: "opacity,scale"
                    from: 0
                    to: 1
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                }

                PropertyAnimation {
                    target: sessionContainer
                    properties: "opacity,scale"
                    from: 0
                    to: 1
                    duration: Appearance.animations.durations.normal
                    easing.bezierCurve: Appearance.animations.curves.emphasizedDecel
                }
            }
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure)
                errorShakeAnimation.start();
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: 0
            to: -8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: -8
            to: 8
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: 8
            to: -4
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.standardAccel
        }
        PropertyAnimation {
            target: inputContainer
            property: "anchors.horizontalCenterOffset"
            from: -4
            to: 0
            duration: Appearance.animations.durations.small * 0.8
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
    }
}
