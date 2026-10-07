pragma ComponentBehavior: Bound

import QtQuick

import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Core.Utils
import qs.Services

Item {
    id: root

    function calculateHeight() {
        var totalHeight = 0;
        var spacing     = 10;
        var padding     = 10;

        if (GlobalStates.isOSDVisible("capslock"))
            totalHeight += 50;
        if (GlobalStates.isOSDVisible("numlock"))
            totalHeight += 50;

        var activeCount = 0;
        if (GlobalStates.isOSDVisible("capslock"))
            activeCount++;
        if (GlobalStates.isOSDVisible("numlock"))
            activeCount++;

        if (activeCount > 1)
            totalHeight += (activeCount - 1) * spacing;

        return totalHeight > 0 ? totalHeight + (padding * 2) : 0;
    }

    implicitHeight: calculateHeight()
    implicitWidth: parent.width * 0.15
    visible: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) // qmllint disable
    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        horizontalCenter: parent.horizontalCenter
        verticalCenter: parent.verticalCenter
    }

    StyledRect {
        anchors.fill: parent
        clip: true
        color: GlobalStates.drawerColors
        radius: Appearance.rounding.large

        Loader {
            active: FocusedMonitor.isOnFocusedMonitor(window.modelData.name) && (GlobalStates.isOSDVisible("numlock") || GlobalStates.isOSDVisible("capslock")) // qmllint disable
            anchors.fill: parent
            asynchronous: true
            sourceComponent: Column {
                spacing: Appearance.spacing.normal

                anchors {
                    fill: parent
                    margins: 15
                }

                Repeater {
                    model: [
                        {
                            osdVisible: "capslock",
                            lock: KeylockState.capsLock,
                            label: qsTr("Caps lock"),
                            icon: KeylockState.capsLock ? "lock" : "lock_open_right"
                        },
                        {
                            osdVisible: "numlock",
                            lock: KeylockState.numLock,
                            label: qsTr("Num Lock"),
                            icon: KeylockState.numLock ? "lock" : "lock_open_right"
                        }
                    ]
                    delegate: LockIndicator {
                        required property var modelData

                        icon: modelData.icon
                        indicator: modelData.lock
                        label: modelData.label
                        osdVisible: modelData.osdVisible
                    }
                }
            }
        }
    }
}
