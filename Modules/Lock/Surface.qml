pragma ComponentBehavior: Bound

import QtQuick
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
        color: "transparent"

        Component.onCompleted: {
            lockSequence.start();
        }

        Clock {
            id: centerClock

            anchors.centerIn: parent
        }
    }

    TopItem {
        id: topItem

        isLockscreenOpen: GlobalStates.isLockscreenOpen
        drawerColors: GlobalStates.drawerColors
        locked: root.lock.locked
        showErrorMessage: root.showErrorMessage
    }

    BottomItem {
        id: bottomItem

        isLockscreenOpen: GlobalStates.isLockscreenOpen
        drawerColors: GlobalStates.drawerColors
        pam: root.pam
    }

    // Confirm dialog — rendered above everything, anchored to lockscreen center
    WrapperRectangle {
        anchors.centerIn: parent
        clip: true
        radius: Appearance.rounding.large
        margin: Appearance.margin.normal
        implicitWidth: column.implicitWidth + 20
        implicitHeight: bottomItem.showConfirmDialog ? column.implicitHeight + 20 : 0
        color: GlobalStates.drawerColors

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }

        Column {
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
                width: column.width
                height: 2
                color: Colours.m3Colors.m3OutlineVariant
            }

            StyledText {
                id: body

                text: qsTr("Do you want to %1?").arg(bottomItem.pendingActionName.toLowerCase())
                font.pixelSize: Appearance.fonts.size.large
                color: Colours.m3Colors.m3OnSurface
                wrapMode: Text.Wrap
                width: Math.max(300, implicitWidth)
            }

            StyledRect {
                width: column.width
                height: 2
                color: Colours.m3Colors.m3OutlineVariant
            }

            Row {
                id: rowButtons

                anchors.right: parent.right
                spacing: Appearance.spacing.normal

                StyledButton {
                    implicitWidth: 80
                    implicitHeight: 40
                    text: qsTr("No")
                    icon.name: "cancel"
                    icon.color: Colours.m3Colors.m3Primary
                    textColor: Colours.m3Colors.m3Primary
                    mdState.backgroundColor: "transparent"
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
                    textColor: Colours.m3Colors.m3Primary
                    text: qsTr("Yes")
                    mdState.backgroundColor: "transparent"
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
        }

        ScriptAction {
            script: {
                GlobalStates.isLockscreenOpen = true;
            }
        }
    }

    SequentialAnimation {
        id: unlockSequence

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
        }

        ScriptAction {
            script: GlobalStates.isLockscreenOpen = false
        }

        ScriptAction {
            script: root.lock.locked = false
        }
    }
}
