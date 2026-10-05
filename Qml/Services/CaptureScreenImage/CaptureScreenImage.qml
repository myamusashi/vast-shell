pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.Services

Singleton {
    id: root

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/screenshot"

    signal notify(string summary, string body, string urgency, string icon, string app, var actions)

    function copyToClipboard(img) {
        internal.copyToClipboard(img);
    }
    function freezeAllScreens(callback) {
        internal.freezeAllScreens(callback);
    }
    function getMonitors(callback) {
        internal.getMonitors(callback);
    }
    function pickWindowForRecord(callback) {
        internal.pickWindowForRecord(callback);
    }
    function screenshotAllOutputs(action) {
        internal.screenshotAllOutputs(action);
    }
    function screenshotOutput(target, action) {
        internal.screenshotOutput(target, action);
    }
    function screenshotSelection(action) {
        internal.screenshotSelection(action);
    }

    // Public API delegating to shared
    function screenshotWindow(action) {
        internal.screenshotWindow(action);
    }

    // Forward shared Screenshotter's notify to wrapper's notify -> sendNotification
    Connections {
        function onNotify(summary, body, urgency, icon, app, actions) {
            root.notify(summary, body, urgency, icon, app, actions);
        }

        target: internal
    }
    Connections {
        function onNotify(summary, body, urgency, icon, app, actions) {
            CaptureNotify.sendNotification(summary, body, urgency, icon, app, actions);
        }

        target: root
    }

    // Shared screenshot/selection/window-picker logic
    PanelScreenshot {
        id: internal

        screenshotDir: root.screenshotDir
    }
    IpcHandler {
        function region(action: string): void {
            root.screenshotSelection(action);
        }
        function screen(action: string): void {
            root.screenshotOutput(Quickshell.screens[0]?.name ?? "", action);
        }
        function window(action: string): void {
            root.screenshotWindow(action);
        }

        target: "captureScreenImage"
    }
}
