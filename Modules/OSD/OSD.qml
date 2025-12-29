pragma ComponentBehavior: Bound

import QtQuick

import qs.Components
import qs.Configs
import qs.Helpers
import qs.Services

StyledRect {
    id: mainRect

    anchors {
        right: parent.right
        bottom: parent.bottom
    }

    implicitWidth: GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock") || GlobalStates.isOSDVisible("volume") ? 250 : 0
    implicitHeight: calculateHeight()
    radius: 0
    topLeftRadius: Appearance.rounding.normal
    color: Colours.m3Colors.m3Background
    visible: window.modelData.name === Hypr.focusedMonitor.name
    clip: true

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    function calculateHeight() {
        var totalHeight = 0;
        var spacing = 10;
        var padding = 10;

        if (GlobalStates.isOSDVisible("capslock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("numlock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("volume"))
            totalHeight += 80;

        var activeCount = 0;
        if (GlobalStates.isOSDVisible("volume"))
            activeCount++;
        if (GlobalStates.isOSDVisible("capslock"))
            activeCount++;
        if (GlobalStates.isOSDVisible("numlock"))
            activeCount++;

        if (activeCount > 1)
            totalHeight += (activeCount - 1) * spacing;

        return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
    }

    Loader {
        anchors.fill: parent
        active: window.modelData.name === Hypr.focusedMonitor.name && GlobalStates.isOSDVisible("volume") || GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock")
        asynchronous: true
        sourceComponent: Column {
            anchors {
                fill: parent
                margins: 15
            }
            spacing: Appearance.spacing.normal

            CapsLockWidget {}

            NumLockWidget {}

            Volumes {}
        }
    }
}
