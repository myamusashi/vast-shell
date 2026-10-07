pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Components.Base.NavigationRail
import qs.Components.Button
import qs.Core.Configs
import qs.Core.States
import qs.Services

import "./Components"
import "./Pages"

LazyLoader {
    id: settingsLoader

    readonly property int contentWidth: 640

    property int          currentPage: 0

    activeAsync: GlobalStates.isSettingsOpen
    component: FloatingWindow {
        color: GlobalStates.drawerColors
        minimumSize: Qt.size(1100, 600)
        title: "settings window"
        onClosed: GlobalStates.isSettingsOpen = false

        Rectangle {
            anchors.fill: parent
            clip: true
            color: "transparent"
            radius: Appearance.rounding.large

            Item {
                anchors.fill: parent
                anchors.margins: Appearance.margin.large

                Rectangle {
                    id: sidebarArea

                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: "transparent"
                    width: navRail.implicitWidth

                    NavigationRail {
                        id: navRail

                        actionButtonIcon: ""
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        backgroundColor: "transparent"
                        currentIndex: settingsLoader.currentPage
                        expanded: true
                        model: [
                            {
                                label: qsTr("General"),
                                items: [
                                    {
                                        icon: "settings",
                                        label: qsTr("General")
                                    },
                                    {
                                        icon: "language",
                                        label: qsTr("Language")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Appearance"),
                                items: [
                                    {
                                        icon: "palette",
                                        label: qsTr("Appearance")
                                    },
                                    {
                                        icon: "wall_art",
                                        label: qsTr("Wallpaper")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Modules"),
                                items: [
                                    {
                                        icon: "table_rows",
                                        label: qsTr("Top Bar")
                                    },
                                    {
                                        icon: "genres",
                                        label: qsTr("Media Player")
                                    },
                                    {
                                        icon: "cloud",
                                        label: qsTr("Weather")
                                    },
                                    {
                                        icon: "notifications",
                                        label: qsTr("Notification")
                                    },
                                    {
                                        icon: "assignment",
                                        label: qsTr("Clipboard")
                                    },
                                    {
                                        icon: "screen_record",
                                        label: qsTr("Capture Video")
                                    },
                                    {
                                        icon: "volume_up",
                                        label: qsTr("Audio")
                                    },
                                    {
                                        icon: "privacy",
                                        label: qsTr("Privacy Nodes")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Connectivity"),
                                items: [
                                    {
                                        icon: "wifi",
                                        label: qsTr("Network & Internet")
                                    },
                                    {
                                        icon: "bluetooth",
                                        label: qsTr("Bluetooth")
                                    },
                                    {
                                        icon: "smartphone",
                                        label: qsTr("KDE Connect")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Session"),
                                items: [
                                    {
                                        icon: "lock_person",
                                        label: qsTr("Greeter")
                                    },
                                    {
                                        icon: "hourglass",
                                        label: qsTr("Idle")
                                    },
                                    {
                                        icon: "lock",
                                        label: qsTr("Lockscreen")
                                    }
                                ]
                            }
                        ]
                        onActivated: function (index) {
                            settingsLoader.currentPage = index;
                        }
                    }
                }

                Rectangle {
                    id: sidebarDivider

                    anchors.bottom: parent.bottom
                    anchors.left: sidebarArea.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.top: parent.top
                    color: Colours.m3Colors.m3OutlineVariant
                    width: 1
                }

                Rectangle {
                    id: contentArea

                    anchors.bottom: parent.bottom
                    anchors.left: sidebarDivider.right
                    anchors.leftMargin: Appearance.spacing.large
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color: "transparent"

                    ColumnLayout {
                        id: pagesColumn

                        function revealCard(cardTitle: string) {
                            const kids = pagesColumn.children;

                            for (let i = 0; i < kids.length; i++) {
                                if (!(kids[i] instanceof Loader) || !kids[i].active || !kids[i].item || !kids[i].item.revealCard)
                                    continue;

                                kids[i].item.revealCard(cardTitle);
                                return;
                            }
                        }

                        anchors.fill: parent

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal
                            z: 2

                            FloatingButton {
                                id: expandToggle

                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: 40
                                Layout.preferredWidth: 40
                                backgroundRadius: Appearance.rounding.small
                                icon.color: Colours.m3Colors.m3SurfaceVariant
                                icon.name: navRail.expanded ? "menu_open" : "menu"
                                icon.size: Appearance.fonts.size.larger
                                onClicked: navRail.expanded = !navRail.expanded
                            }

                            SettingsSearchField {
                                id: settingsSearchField

                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillWidth: true
                                onActivated: (page, card) => {
                                    settingsLoader.currentPage = page;
                                    Qt.callLater(() => pagesColumn.revealCard(card));
                                }
                            }
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 0
                            visible: settingsLoader.currentPage === 0
                            sourceComponent: GeneralPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 1
                            visible: settingsLoader.currentPage === 1
                            sourceComponent: LanguagePage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 2
                            visible: settingsLoader.currentPage === 2
                            sourceComponent: AppearancePage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 3
                            visible: settingsLoader.currentPage === 3
                            sourceComponent: WallpaperPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 4
                            visible: settingsLoader.currentPage === 4
                            sourceComponent: BarPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 5
                            visible: settingsLoader.currentPage === 5
                            sourceComponent: MediaPlayerPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 6
                            visible: settingsLoader.currentPage === 6
                            sourceComponent: WeatherPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 7
                            visible: settingsLoader.currentPage === 7
                            sourceComponent: NotificationPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 8
                            visible: settingsLoader.currentPage === 8
                            sourceComponent: ClipboardPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 9
                            visible: settingsLoader.currentPage === 9
                            sourceComponent: CaptureScreenVideoPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 10
                            visible: settingsLoader.currentPage === 10
                            sourceComponent: VolumePage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 11
                            visible: settingsLoader.currentPage === 11
                            sourceComponent: PrivacyNodesPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 12
                            visible: settingsLoader.currentPage === 12
                            sourceComponent: InternetPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 13
                            visible: settingsLoader.currentPage === 13
                            sourceComponent: BluetoothPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 14
                            visible: settingsLoader.currentPage === 14
                            sourceComponent: KDEConnectPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 15
                            visible: settingsLoader.currentPage === 15
                            sourceComponent: GreeterPage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 16
                            visible: settingsLoader.currentPage === 16
                            sourceComponent: IdlePage {}
                        }

                        Loader {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: settingsLoader.currentPage === 17
                            visible: settingsLoader.currentPage === 17
                            sourceComponent: LockscreenPage {}
                        }
                    }
                }
            }
        }
    }
}
