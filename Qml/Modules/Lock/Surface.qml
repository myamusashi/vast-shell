pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services
import qs.Components.Base

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam           pam

    readonly property list<string>  maskChars: ["║", "║▌█", "║▌", "▌│", "█║", "𝄂▌║", "▌│", "█║", "𝄂▌║"]
    readonly property color         maskColor: {
        if (root.showErrorMessage)
            return Colours.m3Colors.m3Error;
        if (root.pam?.isUnlock ?? false)
            return Colours.m3Colors.m3Green;
        if (root.pam?.unlockInProgress ?? false)
            return Colours.m3Colors.m3OnSurface;
        if (root.inputBuffer.length > 0)
            return Colours.m3Colors.m3Primary;
        return Colours.m3Colors.m3OnSurface;
    }

    property string                 inputBuffer: ""
    property bool                   isAllSelected: false
    property bool                   isClosing: false
    property string                 maskedBuffer: ""
    property var                    maskEntries: []
    property bool                   showErrorMessage: false
    property bool                   zoomedIn: false

    function                        jitterMaskEntry() {
        if (root.maskEntries.length === 0)
            return;
        const idx      = Math.floor(Math.random() * root.maskEntries.length);
        const oldEntry = root.maskEntries[idx];
        const newEntry = root.randomMaskEntry();
        let unitOffset = 0;
        for (let i = 0; i < idx; i++)
            unitOffset += root.maskEntries[i].length;
        root.maskEntries[idx] = newEntry;
        root.maskedBuffer     = root.maskedBuffer.substring(0, unitOffset) + newEntry + root.maskedBuffer.substring(unitOffset + oldEntry.length);
    }
    function                        popMaskEntry() {
        if (root.maskEntries.length === 0)
            return;
        const entry       = root.maskEntries.pop();
        root.maskedBuffer = root.maskedBuffer.substring(0, root.maskedBuffer.length - entry.length);
    }
    function                        pushMaskEntry(entry) {
        root.maskEntries.push(entry);
        root.maskedBuffer += entry;
    }
    function                        randomMaskEntry() {
        return root.maskChars[Math.floor(Math.random() * root.maskChars.length)];
    }

    color: "transparent"
    onInputBufferChanged: {
        var diff = inputBuffer.length - maskEntries.length;
        var grew = diff > 0;
        while (diff > 0) {
            root.pushMaskEntry(root.randomMaskEntry());
            diff--;
        }
        while (diff < 0) {
            root.popMaskEntry();
            diff++;
        }
        isAllSelected = false;
        if (grew && inputBuffer.length > 0 && !zoomedIn) {
            zoomedIn = true;
            zoomInAnimation.start();
        }
    }

    Connections {
        function onUnlock(): void {
            root.isClosing = true;
            unlockSequence.start();
        }

        target: root.lock
    }

    Connections {
        function onShowFailureChanged() {
            if (root.pam.showFailure) {
                root.showErrorMessage = true;
                root.inputBuffer      = "";
                root.maskEntries      = [];
                root.maskedBuffer     = "";
                root.zoomedIn         = false;
                zoomOutAnimation.start();
                errorShakeAnimation.start();
            } else {
                root.showErrorMessage = false;
            }
        }

        enabled: root.pam !== null
        target: root.pam
    }

    Item {
        id: wallpaper

        property real blurRadius: 0

        anchors.fill: parent
        layer.enabled: wallpaper.blurRadius > 0
        opacity: 0
        transformOrigin: Item.Center
        layer.effect: FastBlur {
            radius: wallpaper.blurRadius
            source: wallpaper
            transparentBorder: false
        }
        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
            }
        }

        Image {
            anchors.fill: parent
            asynchronous: true
            cache: true
            source: Paths.currentWallpaper
            fillMode: Image.PreserveAspectCrop
        }
    }

    StyledRect {
        id: rectSurface

        anchors.fill: parent
        color: "transparent"
        focus: true
        radius: 0
        Component.onCompleted: {
            lockSequence.start();
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.inputBuffer.length > 0) {
                    if (root.zoomedIn)
                        zoomOutAnimation.start();

                    root.pam.currentText = root.inputBuffer;
                    root.pam.tryUnlock();
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Backspace) {
                if (root.isAllSelected) {
                    root.inputBuffer   = "";
                    root.isAllSelected = false;
                } else if (event.modifiers & Qt.ControlModifier) {
                    const idx        = root.inputBuffer.lastIndexOf(' ');
                    root.inputBuffer = root.inputBuffer.substring(0, idx > -1 ? idx : 0);
                } else if (root.inputBuffer.length > 0) {
                    root.inputBuffer = root.inputBuffer.substring(0, root.inputBuffer.length - 1);
                }
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                root.isAllSelected = true;
                event.accepted     = true;
                return;
            }

            if (event.key === Qt.Key_Escape) {
                if (root.zoomedIn)
                    zoomOutAnimation.start();

                if (root.isAllSelected)
                    root.isAllSelected = false;
                else
                    root.inputBuffer = "";

                root.zoomedIn  = false;
                event.accepted = true;
                return;
            }

            const text = event.text;
            if (text.length === 1 && text.charCodeAt(0) >= 32) {
                if (root.isAllSelected) {
                    root.inputBuffer   = "";
                    root.isAllSelected = false;
                }
                root.inputBuffer += text;
                event.accepted = true;
            }
        }

        StyledText {
            id: passwordDisplay

            color: root.maskColor
            font.bold: true
            font.pixelSize: Appearance.fonts.size.extraLarge * 10
            horizontalAlignment: Text.AlignHCenter
            opacity: root.inputBuffer.length > 0 || root.showErrorMessage ? 1.0 : 0.3
            text: root.maskedBuffer.length > 0 ? root.maskedBuffer : (root.showErrorMessage ? "" : "·")
            z: 3
            Behavior on opacity {
                NAnim {
                    duration: Appearance.animations.durations.expressiveDefaultSpatial
                    easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                }
            }
            transform: Translate {
                id: passwordShake

                x: 0
            }

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
        }
    }

    Image {
        id: fgLayer

        readonly property bool currentWallpaperIsVideo: MediaKind.isVideo(Paths.currentWallpaper)

        anchors.fill: parent
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        opacity: 0
        scale: 1.0
        source: !currentWallpaperIsVideo && Configs.wallpaper.depthWallpaperEnabled && Configs.wallpaper.depthFgPath !== "" ? "file://" + Configs.wallpaper.depthFgPath : ""
        visible: !currentWallpaperIsVideo && Configs.wallpaper.depthWallpaperEnabled && Configs.wallpaper.depthFgPath !== "" && !DepthWallpaperController.generating && GlobalStates.previewWallpaper === ""
        z: 2
    }

    BottomItem {
        id: bottomItem

        inputBuffer: root.inputBuffer
        isLockscreenOpen: GlobalStates.isLockscreenOpen
        pam: root.pam
        showErrorMessage: root.showErrorMessage
        z: 3
    }

    SequentialAnimation {
        id: lockSequence

        ParallelAnimation {

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "implicitHeight"
                target: bottomItem
                to: 80
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: bottomItem.contentLayout
                to: 1
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: wallpaper
                to: 1
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: fgLayer
                to: 1
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: passwordDisplay
                to: 1
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
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: 18
        }

        NAnim {
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: -18
        }

        NAnim {
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: 12
        }

        NAnim {
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: -12
        }

        NAnim {
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: -6
        }

        NAnim {
            duration: 100
            easing.bezierCurve: Appearance.animations.curves.expressiveFastSpatial
            property: "rotation"
            target: bottomItem.lockIcon
            to: 0
        }

        ScriptAction {
            script: {
                bottomItem.lockIcon.color = Colours.m3Colors.m3Green;
                bottomItem.iconName       = "lock_open_right";
            }
        }

        PauseAnimation {
            duration: Appearance.animations.durations.emphasized
        }

        ParallelAnimation {

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "implicitHeight"
                target: bottomItem
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: bottomItem.contentLayout
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: wallpaper
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "blurRadius"
                target: wallpaper
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: fgLayer
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: passwordDisplay
                to: 0
            }
        }

        ScriptAction {
            script: {
                root.lock.locked              = false;
                GlobalStates.isLockscreenOpen = false;
                root.pam.isUnlock             = false;
                root.pam.currentText          = "";
                root.inputBuffer              = "";
                root.maskEntries              = [];
                root.maskedBuffer             = "";
                root.zoomedIn                 = false;
            }
        }
    }

    SequentialAnimation {
        id: errorShakeAnimation

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: 12
        }

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: -12
        }

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: 8
        }

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: -8
        }

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: 4
        }

        NAnim {
            duration: 50
            property: "x"
            target: passwordShake
            to: 0
        }
    }

    Timer {
        id: jitterTimer

        interval: 2500
        repeat: true
        running: root.inputBuffer.length > 0
        onTriggered: root.jitterMaskEntry()
    }

    SequentialAnimation {
        id: zoomInAnimation

        ParallelAnimation {

            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "scale"
                target: wallpaper
                to: 1.12
            }

            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "blurRadius"
                target: wallpaper
                to: 30
            }

            NAnim {
                duration: Appearance.animations.durations.normal
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "scale"
                target: fgLayer
                to: 1.12
            }

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: bottomItem
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.emphasizedAccel
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "implicitHeight"
                target: bottomItem
                to: 0
            }
        }
    }

    CapsLockPopup {
        anchors.centerIn: parent
        z: 999
    }

    SequentialAnimation {
        id: zoomOutAnimation

        ParallelAnimation {

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "scale"
                target: wallpaper
                to: 1.0
            }

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "blurRadius"
                target: wallpaper
                to: 0
            }

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "scale"
                target: fgLayer
                to: 1.0
            }

            NAnim {
                duration: Appearance.animations.durations.small
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "opacity"
                target: bottomItem
                to: 1
            }

            NAnim {
                duration: Appearance.animations.durations.emphasizedAccel
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
                property: "implicitHeight"
                target: bottomItem
                to: 80
            }
        }
    }
}
