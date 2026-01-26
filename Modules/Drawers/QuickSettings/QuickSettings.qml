pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "Settings"

Item {
    id: root

    anchors {
        left: parent.left
        verticalCenter: parent.verticalCenter
    }

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen

    implicitWidth: isControlCenterOpen ? parent.width * 0.3 : 0
    implicitHeight: parent.height
    visible: window.modelData.name === Hypr.focusedMonitor.name

    function toggleControlCenter(): void {
        GlobalStates.isQuickSettingsOpen = !GlobalStates.isQuickSettingsOpen;
    }

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.TopRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomRightCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
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

    WrapperRectangle {
        id: rect

        anchors.fill: parent
        margin: Appearance.margin.large
        topMargin: 40
        clip: true
        color: GlobalStates.drawerColors
        radius: 0

        ColumnLayout {
            WrapperRectangle {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                implicitWidth: Math.min(parent.width, tabGroup.implicitWidth + 32)
                implicitHeight: 50
                color: Colours.overlayColor(GlobalStates.drawerColors, Colours.m3Colors.m3SurfaceContainer, 0.9)
                margin: Appearance.margin.normal
                radius: Appearance.rounding.full

                TabBar {
                    id: tabGroup

                    Repeater {
                        model: [
                            {
                                "icon": "settings",
                                "name": "Settings",
                                "index": 0
                            },
                            {
                                "icon": "speaker",
                                "name": "Volume",
                                "index": 1
                            },
                            {
                                "icon": "speed",
                                "name": "Performance",
                                "index": 2
                            }
                        ]

                        delegate: TabButton {
                            id: buttonDelegate

                            required property var modelData
                            required property int index

                            implicitWidth: contentItem.implicitWidth + 32
                            implicitHeight: parent.height
                            text: modelData.name

                            contentItem: StyledText {
                                id: textModel

                                text: buttonDelegate.modelData.name
                                font.pixelSize: Appearance.fonts.size.large
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.NoWrap
                                elide: Text.ElideNone
                                color: Colours.m3Colors.m3OnSurface
                            }

                            background: StyledRect {
                                radius: Appearance.rounding.full
                                color: tabGroup.currentIndex === buttonDelegate.modelData.index ? Colours.m3Colors.m3PrimaryContainer : "transparent"
                            }
                        }
                    }
                }
            }

            SwipeView {
                id: controlCenterSwipeView

                Layout.fillWidth: true
                Layout.fillHeight: true

                currentIndex: tabGroup.currentIndex

                onCurrentIndexChanged: {
                    tabGroup.currentIndex = currentIndex;
                }

                Repeater {
                    model: [
                        {
                            component: "Settings",
                            props: {}
                        },
                        {
                            component: "VolumeSettings",
                            props: {
                                implicitWidth: 500
                            }
                        },
                        {
                            component: "Performances",
                            props: {}
                        }
                    ]

                    delegate: StyledRect {
                        required property var modelData

                        radius: 0
                        bottomLeftRadius: Appearance.rounding.normal
                        bottomRightRadius: Appearance.rounding.normal
                        color: Colours.m3Colors.m3Background

                        Loader {
                            anchors {
                                fill: parent
                                leftMargin: 5
                                rightMargin: 5
                                topMargin: 5
                            }
                            active: window.modelData.name === Hypr.focusedMonitor.name
                            asynchronous: true

                            sourceComponent: {
                                switch (parent.modelData.component) {
                                case "Settings":
                                    return settingsComponent;
                                case "VolumeSettings":
                                    return volumeComponent;
                                case "Performances":
                                    return performanceComponent;
                                }
                            }

                            Component {
                                id: settingsComponent

                                Settings {}
                            }

                            Component {
                                id: volumeComponent

                                VolumeSettings {
                                    implicitWidth: 500
                                }
                            }

                            Component {
                                id: performanceComponent

                                Performances {}
                            }
                        }
                    }
                }
            }
        }
    }
}
