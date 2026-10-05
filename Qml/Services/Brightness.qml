pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Vast.Brightness

import qs.Services

Singleton {
    id: root

    readonly property bool available: primaryId !== ""
    property var displays: []
    readonly property int maxValue: 100
    property string primaryId: ""
    property int value: 0

    function applyProfile(name: string) {
        BrightnessManager.applyProfile(name);
    }
    function decreaseBrightness(amount: int) {
        if (!available)
            return;
        BrightnessManager.setBrightness(primaryId, Math.max(0, value - Math.round(amount)));
    }
    function increaseBrightness(amount: int) {
        if (!available)
            return;
        BrightnessManager.setBrightness(primaryId, Math.min(100, value + Math.round(amount)));
    }
    function profileNames(): var {
        return BrightnessManager.profileNames();
    }
    function refresh() {
        const list = BrightnessManager.displays();
        displays = list;
        if (primaryId === "") {
            const internal = list.find(d => d.isInternal);
            primaryId = (internal ?? list[0])?.id ?? "";
        }
        const primary = list.find(d => d.id === primaryId);
        if (primary)
            value = primary.brightness;
    }
    function removeProfile(name: string) {
        BrightnessManager.removeProfile(name);
    }
    function saveProfile(name: string, targets: var) {
        BrightnessManager.saveProfile(name, targets);
    }
    function setBrightness(newValue: int) {
        if (!available)
            return;
        BrightnessManager.setBrightness(primaryId, newValue);
    }
    function setBrightnessAll(percent: int) {
        BrightnessManager.setBrightnessAll(percent);
    }
    function setBrightnessForDisplay(displayId: string, percent: int) {
        BrightnessManager.setBrightness(displayId, percent);
    }
    function setBrightnessGroup(targets: var) {
        BrightnessManager.setBrightnessGroup(targets);
    }
    function setBrightnessPercent(percent: int) {
        if (!available)
            return;
        BrightnessManager.setBrightness(primaryId, percent);
    }

    Component.onCompleted: Qt.callLater(() => {
        BrightnessManager.initialize();
    })

    Connections {
        function onBrightnessChanged(displayId: string, percent: int) {
            root.displays = BrightnessManager.displays();

            if (displayId === root.primaryId)
                root.value = percent;
        }
        function onDisplayListChanged() {
            root.refresh();
        }
        function onInitializationFailed(reason: string) {
            console.warn("BrightnessManager init failed:", reason);
            ToastService.show(qsTr("Brightness unavailable: %1").arg(reason), qsTr("Brightness"), "display-brightness-symbolic", 3000);
        }

        target: BrightnessManager
    }
    IpcHandler {
        function change(delta: int): void {
            const targets = {};
            for (const d of BrightnessManager.displays())
                targets[d.id] = Math.max(0, Math.min(100, d.brightness + delta));
            BrightnessManager.setBrightnessGroup(targets);
        }
        function get(): string {
            return JSON.stringify(BrightnessManager.displays());
        }
        function set(percent: int): void {
            BrightnessManager.setBrightnessAll(percent);
        }

        target: "brightness"
    }
}
