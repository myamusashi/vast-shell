pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.Components.Base.DrawerComponents
import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Core.States
import qs.Services
import "Settings"

Drawer {
    id: root

    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen
    property int saveIndex: 0

    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial
    color: GlobalStates.drawerColors
    cornerRadius: Appearance.rounding.normal
    depth: parent.width * 0.3
    edge: Qt.LeftEdge
    filletRadius: 40
    length: parent.height * 0.8
    open: GlobalStates.isQuickSettingsOpen

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal

        WrapperRectangle {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            color: Colours.overlayColor(GlobalStates.drawerColors, Colours.m3Colors.m3SurfaceContainer, 0.5)
            implicitHeight: 56
            implicitWidth: Math.min(parent.width, tabGroup.implicitWidth + 32)
            margin: Appearance.margin.normal
            radius: Appearance.rounding.full

            ConnectedButtonGroup {
                id: tabGroup

                Layout.fillWidth: true
                currentIndex: root.saveIndex
                fillWidth: true
                model: [
                    {
                        icon: "settings",
                        label: qsTr("Settings")
                    },
                    {
                        icon: "speaker",
                        label: qsTr("Volume")
                    },
                    {
                        icon: "speed",
                        label: qsTr("Performance")
                    }
                ]

                onClicked: index => root.saveIndex = index
            }
        }
        Item {
            id: pageContainer

            property int previousIndex: 0

            Layout.fillHeight: true
            Layout.fillWidth: true

            SettingsPage {
                currentIndex: root.saveIndex
                pageIndex: 0

                content: Component {
                    Settings {
                    }
                }
            }
            SettingsPage {
                currentIndex: root.saveIndex
                pageIndex: 1

                content: Component {
                    VolumeSettings {
                    }
                }
            }
            SettingsPage {
                currentIndex: root.saveIndex
                pageIndex: 2

                content: Component {
                    Performances {
                    }
                }
            }
        }
    }

    component SettingsPage: Item {
        id: animRoot

        required property Component content
        required property int currentIndex
        required property int pageIndex

        anchors.fill: parent
        enabled: currentIndex === pageIndex
        opacity: currentIndex === pageIndex ? 1 : 0
        x: currentIndex === pageIndex ? 0 : currentIndex > pageIndex ? -parent.width * 0.05 : parent.width * 0.05
        z: currentIndex === pageIndex ? 1 : 0

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
            id: pageLoader

            active: animRoot.currentIndex === animRoot.pageIndex
            anchors.fill: parent
            asynchronous: true
            sourceComponent: animRoot.content

            Timer {
                id: unloadTimer

                interval: 30000
                running: !pageLoader.active

                onTriggered: {}
            }
        }
    }
}
