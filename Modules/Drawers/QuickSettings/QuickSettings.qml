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
                implicitHeight: 56
                color: Colours.overlayColor(GlobalStates.drawerColors, Colours.m3Colors.m3SurfaceContainer, 0.5)
                margin: Appearance.margin.normal
                radius: Appearance.rounding.full

                TabBar {
                    id: tabGroup

                    spacing: 2
                    background: Item {}

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

                            contentItem: Item {
                                implicitWidth: rowLayout.implicitWidth
                                implicitHeight: rowLayout.implicitHeight

                                Row {
                                    id: rowLayout

                                    spacing: Appearance.spacing.small
                                    anchors.centerIn: parent

                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: buttonDelegate.modelData.icon
                                        color: tabGroup.currentIndex === buttonDelegate.modelData.index ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3SurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.large
                                    }

                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: buttonDelegate.modelData.name
                                        color: tabGroup.currentIndex === buttonDelegate.modelData.index ? Colours.m3Colors.m3OnPrimary : Colours.m3Colors.m3SurfaceVariant
                                        font.pixelSize: Appearance.fonts.size.large
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideNone
                                    }
                                }
                            }

                            background: StyledRect {
                                radius: {
                                    if (buttonDelegate.modelData.index === 0)
                                        return Appearance.rounding.full;
                                    else if (buttonDelegate.modelData.index === 2)
                                        return Appearance.rounding.full;
                                    else
                                        return 0;
                                }

                                color: tabGroup.currentIndex === buttonDelegate.modelData.index ? Colours.m3Colors.m3Primary : Colours.m3Colors.m3SurfaceContainer
                                topLeftRadius: buttonDelegate.modelData.index === 0 ? Appearance.rounding.full : Appearance.rounding.small
                                bottomLeftRadius: buttonDelegate.modelData.index === 0 ? Appearance.rounding.full : Appearance.rounding.small
                                topRightRadius: buttonDelegate.modelData.index === 2 ? Appearance.rounding.full : Appearance.rounding.small
                                bottomRightRadius: buttonDelegate.modelData.index === 2 ? Appearance.rounding.full : Appearance.rounding.small
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
