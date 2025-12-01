pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Settings"

ColumnLayout {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int state: 0
    property bool triggerAnimation: false
    property bool shouldDestroy: false

    function toggleControlCenter(): void {
        isControlCenterOpen = !isControlCenterOpen;
    }

    onIsControlCenterOpenChanged: {
        if (root.isControlCenterOpen) {
            shouldDestroy = false;
            triggerAnimation = false;
            animationTriggerTimer.restart();
        } else {
            triggerAnimation = false;
            destroyTimer.restart();
        }
    }

    Timer {
        id: animationTriggerTimer
        interval: 50
        repeat: false
        onTriggered: {
            if (root.isControlCenterOpen) {
                root.triggerAnimation = true;
            }
        }
    }

    Timer {
        id: destroyTimer
        interval: Appearance.animations.durations.small + 50
        repeat: false
        onTriggered: {
            root.shouldDestroy = true;
        }
    }

    GlobalShortcut {
        name: "ControlCenter"
        onPressed: root.toggleControlCenter()
    }

    Timer {
        id: cleanup

        interval: 500
        repeat: false
        onTriggered: gc()
    }

    width: Hypr.focusedMonitor.width * 0.3
    height: root.triggerAnimation ? contentHeight : 0
    spacing: 0

    property real contentHeight: tabBar.implicitHeight + divider.implicitHeight + 500

    Behavior on height {
        NAnim {
            duration: Appearance.animations.durations.small
            easing.type: Easing.OutCubic
        }
    }

    anchors {
        top: parent.top
        right: parent.right
        rightMargin: 60
    }

    clip: true

    TabRows {
        id: tabBar

        state: root.state
        scaleFactor: Math.min(1.0, root.width / root.width)
        visible: root.isControlCenterOpen
        topLeftRadius: 0
        topRightRadius: 0

        Layout.fillWidth: true

        onTabClicked: index => {
            root.state = index;
            controlCenterStackView.currentItem.viewIndex = index;
        }
    }

    StyledRect {
        id: divider

        Layout.fillWidth: true
        implicitHeight: root.isControlCenterOpen ? 1 : 0
        visible: root.isControlCenterOpen
        color: Themes.m3Colors.m3OutlineVariant

        Behavior on implicitHeight {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }
    }

    StackView {
        id: controlCenterStackView

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 500

        property Component viewComponent: contentView

        initialItem: viewComponent

        onCurrentItemChanged: {
            if (currentItem)
                currentItem.viewIndex = root.state;
        }

        Component {
            id: contentView

            StyledRect {
                id: shapeRect

                anchors.fill: parent

                radius: 0
                bottomLeftRadius: Appearance.rounding.normal
                bottomRightRadius: Appearance.rounding.normal
                color: Themes.m3Colors.m3Background

                property int viewIndex: 0

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 0
                    asynchronous: true
                    visible: active

                    sourceComponent: Settings {}
                }

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 1
                    asynchronous: true
                    visible: active

                    sourceComponent: VolumeSettings {}
                }

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 2
                    asynchronous: true
                    visible: active

                    sourceComponent: Performances {}
                }

                Loader {
                    anchors.fill: parent
                    active: parent.viewIndex === 3
                    asynchronous: true
                    visible: active

                    sourceComponent: Weathers {}
                }
            }
        }
    }
}
