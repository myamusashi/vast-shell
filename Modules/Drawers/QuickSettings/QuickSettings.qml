pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Widgets

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
    implicitHeight: parent.height * 0.8
    visible: window.modelData.name === Hypr.focusedMonitor.name

    Behavior on implicitWidth {
        NAnim {
            duration: Appearance.animations.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.animations.curves.expressiveDefaultSpatial
        }
    }

    Corner {
        location: Qt.TopLeftCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    Corner {
        location: Qt.BottomLeftCorner
        extensionSide: Qt.Vertical
        radius: GlobalStates.isQuickSettingsOpen ? 40 : 0
        color: GlobalStates.drawerColors
    }

    WrapperRectangle {
        id: rect

        anchors.fill: parent
        margin: Appearance.margin.large
        topMargin: 40
        clip: true
        color: GlobalStates.drawerColors
        radius: 0
        topRightRadius: Appearance.rounding.normal
        bottomRightRadius: Appearance.rounding.normal

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
                onCurrentIndexChanged: tabGroup.currentIndex = currentIndex

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

                        Loader {
                            anchors {
                                fill: parent
                                leftMargin: 20
                                rightMargin: 20
                                topMargin: 5
                            }
                            active: true
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
