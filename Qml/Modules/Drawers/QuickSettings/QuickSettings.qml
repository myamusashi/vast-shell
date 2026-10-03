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

    property int saveIndex: 0
    property bool isControlCenterOpen: GlobalStates.isQuickSettingsOpen

    edge: Qt.LeftEdge
    open: GlobalStates.isQuickSettingsOpen
    depth: parent.width * 0.3
    length: parent.height * 0.8
    cornerRadius: Appearance.rounding.normal
    filletRadius: 40
    color: GlobalStates.drawerColors
    animationDuration: Appearance.animations.durations.expressiveDefaultSpatial
    animationEasingCurve: Appearance.animations.curves.expressiveDefaultSpatial

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.normal
        WrapperRectangle {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            implicitWidth: Math.min(parent.width, tabGroup.implicitWidth + 32)
            implicitHeight: 56
            color: Colours.overlayColor(GlobalStates.drawerColors, Colours.m3Colors.m3SurfaceContainer, 0.5)
            margin: Appearance.margin.normal
            radius: Appearance.rounding.full

            ConnectedButtonGroup {
                id: tabGroup

                Layout.fillWidth: true
                fillWidth: true
                currentIndex: root.saveIndex

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

            Layout.fillWidth: true
            Layout.fillHeight: true

            property int previousIndex: 0

            SettingsPage {
                pageIndex: 0
                currentIndex: root.saveIndex
                content: Component {
                    Settings {}
                }
            }

            SettingsPage {
                pageIndex: 1
                currentIndex: root.saveIndex
                content: Component {
                    VolumeSettings {}
                }
            }

            SettingsPage {
                pageIndex: 2
                currentIndex: root.saveIndex
                content: Component {
                    Performances {}
                }
            }
        }
    }

    component SettingsPage: Item {
        id: animRoot

        required property int pageIndex
        required property int currentIndex
        required property Component content

        anchors.fill: parent
        opacity: currentIndex === pageIndex ? 1 : 0
        x: currentIndex === pageIndex ? 0 : currentIndex > pageIndex ? -parent.width * 0.05 : parent.width * 0.05
        enabled: currentIndex === pageIndex
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

            anchors.fill: parent
            asynchronous: true
            sourceComponent: animRoot.content
            active: animRoot.currentIndex === animRoot.pageIndex

            Timer {
                id: unloadTimer

                interval: 30000
                running: !pageLoader.active
                onTriggered: {}
            }
        }
    }
}
