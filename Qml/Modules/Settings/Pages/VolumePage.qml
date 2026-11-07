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

    function     revealCard(cardTitle: string): bool {
        const tabByCard = {
            "Playback": 0,
            "Output Devices": 1,
            "Input Devices": 2,
            "Configuration": 3,
            "Level Meters": 3
        };
        if (tabByCard[cardTitle] !== undefined && root.currentTab !== tabByCard[cardTitle])
            root.currentTab = tabByCard[cardTitle];

        const targetCard = cardTitle === "Configuration" ? "Level Meters" : cardTitle;
        return root.revealer.reveal(targetCard);
    }

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

        TabLoader {
            tabIndex: 0
            sourceComponent: PlaybackTab {}
        }

        TabLoader {
            tabIndex: 1
            sourceComponent: OutputDevicesTab {}
        }

        TabLoader {
            tabIndex: 2
            sourceComponent: InputDevicesTab {}
        }

        TabLoader {
            tabIndex: 3
            sourceComponent: ConfigurationTab {}
        }
    }

    component TabLoader: Loader {
        id: tabLoader

        required property int  tabIndex

        readonly property bool isCurrentTab: root.currentTab === tabIndex

        property bool          keepAlive: false

        Layout.fillHeight: true
        Layout.fillWidth: true
        active: isCurrentTab || keepAlive
        visible: isCurrentTab
        onIsCurrentTabChanged: {
            if (isCurrentTab)
                keepAlive = true;
        }

        Timer {
            interval: 60000
            running: tabLoader.keepAlive && !tabLoader.isCurrentTab
            onTriggered: tabLoader.keepAlive = false
        }
    }
}
