pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    property bool isClosing: false
    property bool showErrorMessage: false

    color: "transparent"

    Connections {
        target: root.lock

        function onUnlock(): void {
            root.isClosing = true;
            unlockSequence.start();
        }
    }

    Connections {
        target: root.pam
        enabled: root.pam !== null

        function onShowFailureChanged() {
            if (root.pam.showFailure)
                root.showErrorMessage = true;
            else
                root.showErrorMessage = false;
        }
    }

    ScreencopyView {
        id: wallpaper

        anchors.fill: parent

        property int blurSize: 0

        captureSource: root.screen
        live: false
        layer.enabled: true
        layer.effect: FastBlur {
            source: wallpaper
            radius: wallpaper.blurSize
        }
    }

    StyledRect {
        id: rectSurface

        anchors.fill: parent

        radius: 0
        color: Qt.alpha(Colours.m3Colors.m3Background, 0.3)

        Component.onCompleted: {
            lockSequence.start();
        }

        Clock {
            id: centerClock

            anchors.centerIn: parent
            z: 1
        }

        TopItem {
            id: topItem

            isLockscreenOpen: GlobalStates.isLockscreenOpen
            drawerColors: GlobalStates.drawerColors
            locked: root.lock.locked
            showErrorMessage: root.showErrorMessage
        }

        RightItem {
            id: rightItem

            isLockscreenOpen: GlobalStates.isLockscreenOpen
        }

        BottomItem {
            id: bottomItem

            isLockscreenOpen: GlobalStates.isLockscreenOpen
            drawerColors: GlobalStates.drawerColors
            isUnlock: root.pam.isUnlock
            pam: root.pam
        }
    }

    WrapperRectangle {
        anchors.centerIn: parent

        clip: true
        radius: Appearance.rounding.large
        margin: Appearance.margin.normal
        implicitWidth: column.implicitWidth * 2
        implicitHeight: bottomItem.showConfirmDialog ? column.implicitHeight + 20 : 0
        color: GlobalStates.drawerColors

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ColumnLayout {
            id: column

            spacing: Appearance.spacing.large

            StyledText {
                id: header

                text: qsTr("Session")
                color: Colours.m3Colors.m3OnSurface
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.bold: true
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: Colours.m3Colors.m3OutlineVariant
            }

            StyledText {
                id: body

                text: qsTr("Do you want to %1?").arg(bottomItem.pendingActionName.toLowerCase())
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
                wrapMode: Text.Wrap
                Layout.fillWidth: Math.max(300, implicitWidth)
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.preferredHeight: 2
                color: Colours.m3Colors.m3OutlineVariant
            }

            Row {
                id: rowButtons

                Layout.alignment: Qt.AlignRight
                spacing: Appearance.spacing.normal

                StyledButton {
                    implicitWidth: 80
                    implicitHeight: 40
                    text: qsTr("No")
                    icon.name: "cancel"
                    icon.color: Colours.m3Colors.m3Primary
                    textColor: Colours.m3Colors.m3Primary
                    color: "transparent"
                    onClicked: {
                        bottomItem.showConfirmDialog = false;
                        bottomItem.pendingAction = null;
                        bottomItem.pendingActionName = "";
                    }
                }

                StyledButton {
                    implicitWidth: 80
                    implicitHeight: 40
                    icon.name: "check"
                    icon.color: Colours.m3Colors.m3Primary
                    rippleColor: Qt.alpha(Colours.m3Colors.m3SecondaryContainer, 0)
                    textColor: Colours.m3Colors.m3Primary
                    text: qsTr("Yes")
                    color: "transparent"
                    onClicked: {
                        if (bottomItem.pendingAction)
                            bottomItem.pendingAction();
                        bottomItem.showConfirmDialog = false;
                        bottomItem.pendingAction = null;
                        bottomItem.pendingActionName = "";
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: lockSequence

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 80
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem
                property: "implicitWidth"
                to: Hypr.focusedMonitor.width * 0.2
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: centerClock.clockLayout
                property: "opacity"
                to: 1
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurSize"
                to: 64
            }

            NAnim {
                target: topItem.leftCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topItem.rightCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem.leftCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem.rightCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem.leftCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem.rightCorner
                property: "radius"
                to: 40
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: {
                GlobalStates.isLockscreenOpen = true;
            }
        }
    }

    SequentialAnimation {
        id: unlockSequence

        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: 18
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: -18
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: 12
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: -12
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: 6
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: -6
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        NAnim {
            target: topItem.lockIcon
            property: "rotation"
            to: 0
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }
        CAnim {
            target: topItem.lockIcon
            property: "color"
            to: Colours.m3Colors.m3Green
            duration: Appearance.animations.durations.small
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
        }

        ScriptAction {
            script: topItem.iconName = "lock_open_right"
        }

        PauseAnimation {
            duration: 500
        }

        ParallelAnimation {
            NAnim {
                target: topItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem
                property: "implicitHeight"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem
                property: "implicitWidth"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: centerClock.clockLayout
                property: "opacity"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: wallpaper
                property: "blurSize"
                to: 0
            }

            NAnim {
                target: bottomItem.leftCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: bottomItem.rightCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topItem.leftCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: topItem.rightCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem.leftCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }

            NAnim {
                target: rightItem.rightCorner
                property: "radius"
                to: 0
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        ScriptAction {
            script: {
                root.lock.locked = false;
                GlobalStates.isLockscreenOpen = false;
                root.pam.isUnlock = false;
                root.pam.currentText = "";
            }
        }
    }
}
