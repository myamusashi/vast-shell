pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Settings"

Item {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int state: 0

    implicitWidth: parent.width * 0.8
    implicitHeight: isControlCenterOpen ? 400 : 0
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitHeight {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    anchors {
        top: parent.top
        horizontalCenter: parent.horizontalCenter
    }

    function toggleControlCenter(): void {
        GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
    }

    OuterRoundedCorner {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -radius
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        corner: 3
        bgColor: Colours.m3Colors.m3Surface

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    OuterRoundedCorner {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -radius
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        corner: 2
        bgColor: Colours.m3Colors.m3Surface

        Behavior on radius {
            NAnim {
                duration: Appearance.animations.durations.expressiveDefaultSpatial
                easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
            }
        }
    }

    GlobalShortcut {
        name: "QuickSettings"
        onPressed: root.toggleControlCenter()
    }

    IpcHandler {
        target: "QuickSettings"

        function open(): void {
            GlobalStates.isQuickSettingsOpen = true;
        }
        function close(): void {
            GlobalStates.isQuickSettingsOpen = false;
        }
        function toggle(): void {
            GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
        }
    }

    StyledRect {
        id: rect

        anchors.fill: parent
        clip: true
        color: Colours.m3Colors.m3Surface
        radius: 0
        bottomLeftRadius: Appearance.rounding.large
        bottomRightRadius: Appearance.rounding.large

        Loader {
            anchors.fill: parent
            active: GlobalStates.isQuickSettingsOpen
            asynchronous: true
            sourceComponent: RowLayout {
                anchors.fill: parent

                TabColumn {
                    id: tabBar

                    state: root.state
                    color: rect.color
                    scaleFactor: Math.min(1.0, root.width / root.width)
                    visible: root.isControlCenterOpen
                    Layout.fillWidth: true
                    tabs: [
                        {
                            "icon": "settings",
                            "index": 0
                        },
                        {
                            "icon": "speaker",
                            "index": 1
                        },
                        {
                            "icon": "speed",
                            "index": 2
                        }
                    ]
                    onTabClicked: index => {
                        root.state = index;
                        controlCenterStackView.currentItem.viewIndex = index;
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.5
                    Layout.fillHeight: true
                    spacing: 0

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
                                anchors.topMargin: 10

                                radius: 0
                                bottomLeftRadius: Appearance.rounding.normal
                                bottomRightRadius: Appearance.rounding.normal
                                color: Colours.m3Colors.m3Background

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
                            }
                        }
                    }
                }
            }
        }
    }
}
