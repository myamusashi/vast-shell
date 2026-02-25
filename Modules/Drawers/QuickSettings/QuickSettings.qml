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
    property int saveIndex: 0

    implicitWidth: isControlCenterOpen ? parent.width * 0.3 : 0
    implicitHeight: parent.height * 0.8
    visible: !Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name

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

        Loader {
            anchors.fill: parent
            active: (!Configs.generals.followFocusMonitor || window.modelData.name === Hypr.focusedMonitor.name) && root.isControlCenterOpen
            asynchronous: true

            sourceComponent: ColumnLayout {
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
                        currentIndex: root.saveIndex
                        onCurrentIndexChanged: root.saveIndex = currentIndex

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

                Item {
                    id: pageContainer

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    property int previousIndex: 0

                    Page {
                        pageIndex: 0
                        currentIndex: root.saveIndex
                        content: Component {
                            Settings {}
                        }
                    }

                    Page {
                        pageIndex: 1
                        currentIndex: root.saveIndex
                        content: Component {
                            VolumeSettings {
                                implicitWidth: 500
                            }
                        }
                    }

                    Page {
                        pageIndex: 2
                        currentIndex: root.saveIndex
                        content: Component {
                            Performances {}
                        }
                    }
                }
            }
        }
    }

    component Page: Item {
        id: animRoot

        required property int pageIndex
        required property int currentIndex
        required property Component content

        anchors.fill: parent
        opacity: currentIndex === pageIndex ? 1 : 0
        x: currentIndex === pageIndex ? 0 : currentIndex > pageIndex ? -parent.width * 0.05 : parent.width * 0.05
        enabled: currentIndex === pageIndex

        Behavior on opacity {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Behavior on x {
            NAnim {
                duration: Appearance.animations.durations.small
            }
        }

        Loader {
            anchors.fill: parent
            asynchronous: true
            sourceComponent: animRoot.content

            property bool visited: false
            active: animRoot.currentIndex === animRoot.pageIndex || visited
            onActiveChanged: if (active)
                visited = true
        }
    }
}
