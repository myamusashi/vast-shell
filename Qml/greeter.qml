//@ pragma DiskCache
//@ pragma RenderControl
//@ pragma NativeTextRendering
//@ pragma DropExpensiveFonts
//@ pragma Env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi
//@ pragma Env QT_FFMPEG_ENCODING_HW_DEVICE_TYPES=vaapi

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland

import qs.Core.Configs
import qs.Greeter

ShellRoot {
    id: root

    function beginUnlockAndLaunch() {
        if (!rootFlow.exiting || rootFlow.unlocking)
            return;
        rootFlow.unlocking = true;
        exitFallbackTimer.stop();
        sessionLock.locked = false;
        // Wait ~2 frames so Wayland flushes ext_session_lock_v1.unlock_and_destroy
        // before Greetd.launch() exits Quickshell, avoiding the compositor dead-lock screen.
        launchCommitTimer.restart();
    }

    WlSessionLock {
        id: sessionLock

        locked: true

        Surface {
            auth: authenticator // qmllint disable
            lock: sessionLock
            onExitCompleted: root.beginUnlockAndLaunch()
        }
    }

    Auth {
        id: authenticator
    }

    Scope {
        id: rootFlow

        property bool exiting: false
        property bool launching: false
        property bool unlocking: false
    }

    Connections {

        function onLaunchReady() {
            if (rootFlow.exiting || rootFlow.launching)
                return;
            rootFlow.exiting = true;
            exitFallbackTimer.restart();
        }

        target: authenticator
    }

    Connections {

        function onError() {
            exitFallbackTimer.stop();
            launchCommitTimer.stop();
            rootFlow.exiting   = false;
            rootFlow.unlocking = false;
            rootFlow.launching = false;
            sessionLock.locked = true;
        }

        target: Greetd
    }

    // Safety fallback if no WlSessionLockSurface instances exist (e.g. headless output).
    Timer {
        id: exitFallbackTimer

        interval: Appearance.animations.durations.expressiveFastSpatial + 150
        onTriggered: root.beginUnlockAndLaunch()
    }

    Timer {
        id: launchCommitTimer

        interval: 32
        onTriggered: {
            rootFlow.launching = true;
            authenticator.launch();
        }
    }

    // Solid-black backdrop beneath WlSessionLock so unlocking never flashes a
    // non-black compositor root background on any Wayland compositor.
    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property ShellScreen modelData

            WlrLayershell.layer: WlrLayer.Background
            color: "#000000"
            exclusionMode: ExclusionMode.Ignore
            screen: modelData
            surfaceFormat.opaque: true

            anchors {
                bottom: true
                left: true
                right: true
                top: true
            }
        }
    }
}
