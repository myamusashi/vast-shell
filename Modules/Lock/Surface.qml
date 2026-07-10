pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import qs.Core.Configs
import qs.Core.States
import qs.Services
import qs.Components.Base

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    property bool isClosing: false
    property bool showErrorMessage: false

    color: "transparent"

    property string inputBuffer: ""
    property string maskedBuffer: ""
    readonly property list<string> maskChars: ["m", "y", "a", "m", "u", "s", "a", "s", "h", "i"]
    property bool isAllSelected: false

    onInputBufferChanged: {
        var diff = root.inputBuffer.length - root.maskedBuffer.length;
        while (diff > 0) {
            root.maskedBuffer += root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
            diff--;
        }
        while (diff < 0) {
            root.maskedBuffer = root.maskedBuffer.substring(0, root.maskedBuffer.length - 1);
            diff++;
        }
        root.isAllSelected = false;
    }

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
            if (root.pam.showFailure) {
                root.showErrorMessage = true;
                root.inputBuffer = "";
                root.maskedBuffer = "";
                errorShakeAnimation.start();
            } else {
                root.showErrorMessage = false;
            }
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

        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.inputBuffer.length > 0) {
                    root.pam.currentText = root.inputBuffer;
                    root.pam.tryUnlock();
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.isAllSelected = false;
                } else if (event.modifiers & Qt.ControlModifier) {
                    const idx = root.inputBuffer.lastIndexOf(' ');
                    root.inputBuffer = root.inputBuffer.substring(0, idx > -1 ? idx : 0);
                } else if (root.inputBuffer.length > 0) {
                    root.inputBuffer = root.inputBuffer.substring(0, root.inputBuffer.length - 1);
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                root.isAllSelected = true;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Escape) {
                if (root.isAllSelected) {
                    root.isAllSelected = false;
                } else {
                    root.inputBuffer = "";
                }
                event.accepted = true;
                return;
            }

            const text = event.text;
            if (text.length === 1 && text.charCodeAt(0) >= 32) {
                if (root.isAllSelected) {
                    root.inputBuffer = "";
                    root.isAllSelected = false;
                }
                root.inputBuffer += text;
                event.accepted = true;
            }
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
            inputBuffer: root.inputBuffer
        }

        StyledText {
            id: passwordDisplay

            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            text: root.maskedBuffer.length > 0 ? root.maskedBuffer : (root.showErrorMessage ? "" : "·")
            color: root.showErrorMessage ? Colours.m3Colors.m3Error : root.isAllSelected ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.extraLarge * 5
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            z: 1
            opacity: root.inputBuffer.length > 0 || root.showErrorMessage ? 1.0 : 0.3

            transform: Translate {
                id: passwordShake
                x: 0
            }
        }

        StyledText {
            id: errorLabel

            anchors {
                top: passwordDisplay.bottom
                topMargin: 16
                horizontalCenter: parent.horizontalCenter
            }

            text: "WRONG"
            color: Colours.m3Colors.m3Error
            font.pixelSize: Appearance.fonts.size.large
            font.bold: true
            opacity: root.showErrorMessage ? 1 : 0

            Behavior on opacity {
                NAnim {
                    duration: 200
                }
            }
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
                target: topItem.clockLayout
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
                target: topItem.clockLayout
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

    Timer {
        id: jitterTimer
        interval: 2500
        repeat: true
        running: root.inputBuffer.length > 0
        onTriggered: {
            const idx = Math.floor(Math.random() * root.inputBuffer.length);
            const arr = root.maskedBuffer.split('');
            arr[idx] = root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
            root.maskedBuffer = arr.join('');
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        NumberAnimation {
            target: passwordShake
            property: "x"
            to: 12
            duration: 50
        }
        NumberAnimation {
            target: passwordShake
            property: "x"
            to: -12
            duration: 50
        }
        NumberAnimation {
            target: passwordShake
            property: "x"
            to: 8
            duration: 50
        }
        NumberAnimation {
            target: passwordShake
            property: "x"
            to: -8
            duration: 50
        }
        NumberAnimation {
            target: passwordShake
            property: "x"
            to: 4
            duration: 50
        }
        NumberAnimation {
            target: passwordShake
            property: "x"
            to: 0
            duration: 50
        }
    }
}
