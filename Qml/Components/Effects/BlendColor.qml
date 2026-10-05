pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vast.Utils

import qs.Core.Configs
import qs.Components.Base

Scope {
    id: root

    property NAnim blendAnim: NAnim {
        duration: root.duration
        from: 0.0
        property: "colorBlendProgress"
        target: root
        to: 1.0
    }
    property real colorBlendProgress: 1.0
    property bool colorBlending: false
    property color colorFrom: "transparent"
    property color colorTo: "transparent"
    property int duration: Appearance.animations.durations.small
    required property Item host
    property color target: "transparent"

    function blendTo(next) {
        if (next === host["color"] && !colorBlending) // qmllint disable missing-property
            return;
        blendAnim.stop();
        colorFrom = host["color"]; // qmllint disable missing-property
        colorTo = next;
        colorBlending = true;
        colorBlendProgress = 0.0;
        blendAnim.start();
    }

    onColorBlendProgressChanged: {
        if (!colorBlending)
            return;
        if (colorBlendProgress >= 1) {
            host["color"] = colorTo; // qmllint disable missing-property
            colorBlending = false;
        } else if (colorBlendProgress > 0) {
            host["color"] = ColorUtils.blendColors(colorFrom, colorTo, colorBlendProgress); // qmllint disable missing-property
        }
    }
    onTargetChanged: root.blendTo(target)
}
