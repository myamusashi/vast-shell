pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower

import qs.Core.Configs
import qs.Services
import Vast.Utils

Elevation {
    id: elevation

    property bool flashInActive: false
    property real flashInBlend: 1.0
    property color flashInFrom
    property color flashInTo
    property bool flashOutActive: false
    property real flashOutBlend: 1.0
    property color flashOutFrom
    property color flashOutTo

    anchors.fill: parent
    blur: 0
    color: "transparent"
    level: 3
    spread: 0
    z: -1

    onFlashInBlendChanged: {
        if (!flashInActive)
            return;
        if (flashInBlend >= 1) {
            color = flashInTo;
            flashInActive = false;
        } else if (flashInBlend > 0) {
            color = ColorUtils.blendColors(flashInFrom, flashInTo, flashInBlend);
        }
    }
    onFlashOutBlendChanged: {
        if (!flashOutActive)
            return;
        if (flashOutBlend >= 1) {
            color = flashOutTo;
            flashOutActive = false;
        } else if (flashOutBlend > 0) {
            color = ColorUtils.blendColors(flashOutFrom, flashOutTo, flashOutBlend);
        }
    }

    NAnim {
        id: flashInAnim

        duration: Appearance.animations.durations.large * 0.8
        from: 0.0
        property: "flashInBlend"
        target: elevation
        to: 1.0
    }
    NAnim {
        id: flashOutAnim

        duration: Appearance.animations.durations.large
        from: 0.0
        property: "flashOutBlend"
        target: elevation
        to: 1.0
    }
    SequentialAnimation {
        id: chargeFlash

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashInAnim.stop();
                    flashInFrom = elevation.color;
                    flashInTo = Colours.m3Colors.m3Green;
                    flashInActive = true;
                    flashInBlend = 0.0;
                    flashInAnim.start();
                }
            }
            NAnim {
                duration: Appearance.animations.durations.large * 0.8
                property: "blur"
                target: elevation
                to: Configs.generals.chargingGlowSpread
            }
            NAnim {
                duration: Appearance.animations.durations.large * 0.8
                property: "spread"
                target: elevation
                to: Configs.generals.chargingGlowSpread
            }
        }
        PauseAnimation {
            duration: 800
        }
        ParallelAnimation {
            ScriptAction {
                script: {
                    flashOutAnim.stop();
                    flashOutFrom = elevation.color;
                    flashOutTo = "transparent";
                    flashOutActive = true;
                    flashOutBlend = 0.0;
                    flashOutAnim.start();
                }
            }
            NAnim {
                duration: Appearance.animations.durations.large
                property: "blur"
                target: elevation
                to: 0
            }
            NAnim {
                duration: Appearance.animations.durations.large
                property: "spread"
                target: elevation
                to: 0
            }
        }
    }
    SequentialAnimation {
        id: lowFlash

        ParallelAnimation {
            ScriptAction {
                script: {
                    flashInAnim.stop();
                    flashInFrom = elevation.color;
                    flashInTo = Colours.m3Colors.m3Red;
                    flashInActive = true;
                    flashInBlend = 0.0;
                    flashInAnim.start();
                }
            }
            NAnim {
                duration: Appearance.animations.durations.large * 0.8
                property: "blur"
                target: elevation
                to: 20
            }
            NAnim {
                duration: Appearance.animations.durations.large * 0.8
                property: "spread"
                target: elevation
                to: 20
            }
        }
        PauseAnimation {
            duration: 800
        }
        ParallelAnimation {
            ScriptAction {
                script: {
                    flashOutAnim.stop();
                    flashOutFrom = elevation.color;
                    flashOutTo = "transparent";
                    flashOutActive = true;
                    flashOutBlend = 0.0;
                    flashOutAnim.start();
                }
            }
            NAnim {
                duration: Appearance.animations.durations.large
                property: "blur"
                target: elevation
                to: 0
            }
            NAnim {
                duration: Appearance.animations.durations.large
                property: "spread"
                target: elevation
                to: 0
            }
        }
    }
    Connections {
        function onPercentageChanged() {
            const percentage = Math.round(UPower.displayDevice.percentage * 100);
            const levels = Configs.generals.battery.warnLevels;
            const warn = levels.find(e => e.level === percentage);

            if (warn) {
                lowFlash.restart();
                CaptureNotify.sendNotification(warn.title, warn.message, warn.level === percentage ? warn.urgency : "normal", warn.icon, "vast-shell", []);
            }
        }
        function onStateChanged() {
            if (UPower.displayDevice.state === UPowerDeviceState.Charging)
                chargeFlash.restart();
        }

        target: UPower.displayDevice
    }
}
