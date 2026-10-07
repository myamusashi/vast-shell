pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Button

import "../Components"
import "./Volume"

SettingsPageBase {
    id: root

    property int currentTab: 0

    pageTitle: qsTr("Volume")

    ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: Appearance.margin.large
        spacing: Appearance.spacing.large

        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Item {
                Layout.fillWidth: true
            }

            ConnectedButtonGroup {
                id: tabBar

                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                currentIndex: root.currentTab
                fillWidth: true
                model: [
                    {
                        icon: "graphic_eq",
                        label: qsTr("Playback")
                    },
                    {
                        icon: "speaker",
                        label: qsTr("Output Devices")
                    },
                    {
                        icon: "mic",
                        label: qsTr("Input Devices")
                    },
                    {
                        icon: "tune",
                        label: qsTr("Configuration")
                    }
                ]
                onClicked: idx => root.currentTab = idx
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            active: root.currentTab === 0
            visible: root.currentTab === 0
            sourceComponent: PlaybackTab {}
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            active: root.currentTab === 1
            visible: root.currentTab === 1
            sourceComponent: OutputDevicesTab {}
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            active: root.currentTab === 2
            visible: root.currentTab === 2
            sourceComponent: InputDevicesTab {}
        }

        Loader {
            Layout.fillHeight: true
            Layout.fillWidth: true
            active: root.currentTab === 3
            visible: root.currentTab === 3
            sourceComponent: ConfigurationTab {}
        }
    }
}
