pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.Services

Singleton {
    id: root

    readonly property string screenshotDir: Quickshell.env("HOME") + "/Pictures/screenshot"

    signal notify(string summary, string body, string urgency, string icon, string app, var actions)

    // Forward shared Screenshotter's notify to wrapper's notify -> sendNotification
    Connections {
        target: internal
        function onNotify(summary, body, urgency, icon, app, actions) {
            root.notify(summary, body, urgency, icon, app, actions);
        }
    }

    Connections {
        target: root
        function onNotify(summary, body, urgency, icon, app, actions) {
            CaptureNotify.sendNotification(summary, body, urgency, icon, app, actions);
        }
    }

    // Shared screenshot/selection/window-picker logic
    PanelScreenshot {
        id: internal

        screenshotDir: root.screenshotDir
    }

    // Public API delegating to shared
    function screenshotWindow(action) {
        internal.screenshotWindow(action);
    }
    function screenshotSelection(action) {
        internal.screenshotSelection(action);
    }
    function screenshotOutput(target, action) {
        internal.screenshotOutput(target, action);
    }
    function screenshotAllOutputs(action) {
        internal.screenshotAllOutputs(action);
    }
    function pickWindowForRecord(callback) {
        internal.pickWindowForRecord(callback);
    }
    function getMonitors(callback) {
        internal.getMonitors(callback);
    }
    function freezeAllScreens(callback) {
        internal.freezeAllScreens(callback);
    }
    function copyToClipboard(img) {
        internal.copyToClipboard(img);
    }
}
