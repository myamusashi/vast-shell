pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Vast.Utils

import qs.Core.Configs
import qs.Components.Base

Scope {
    id: root

    required property Item host
    property int duration: Appearance.animations.durations.small
    property color target: "transparent"

    property color colorFrom: "transparent"
    property color colorTo: "transparent"
    property bool colorBlending: false
    property real colorBlendProgress: 1.0

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

    onTargetChanged: root.blendTo(target)

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

    property NAnim blendAnim: NAnim {
        target: root
        property: "colorBlendProgress"
        from: 0.0
        to: 1.0
        duration: root.duration
    }
}
