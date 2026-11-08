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
import "./Pages/Hyprland"

LazyLoader {
    id: settingsLoader

    readonly property int contentWidth: 640

    property int          currentPage: 0
    property real         railScrollPosition: 0

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
                        scrollPosition: settingsLoader.railScrollPosition
                        onScrollPositionChanged: settingsLoader.railScrollPosition = scrollPosition
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
                                    },
                                    {
                                        icon: "dock_to_bottom",
                                        label: qsTr("Dock")
                                    },
                                    {
                                        icon: "description",
                                        label: qsTr("Templates")
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
                            },
                            {
                                label: qsTr("System"),
                                items: [
                                    {
                                        icon: "info",
                                        label: qsTr("About")
                                    }
                                ]
                            },
                            {
                                label: qsTr("Hyprland Configurations"),
                                items: [
                                    {
                                        icon: "monitor",
                                        label: qsTr("Monitors")
                                    },
                                    {
                                        icon: "tune",
                                        label: qsTr("General")
                                    },
                                    {
                                        icon: "format_color_fill",
                                        label: qsTr("Decoration")
                                    },
                                    {
                                        icon: "sliders",
                                        label: qsTr("Input")
                                    },
                                    {
                                        icon: "view_column",
                                        label: qsTr("Group")
                                    },
                                    {
                                        icon: "category",
                                        label: qsTr("Misc")
                                    },
                                    {
                                        icon: "settings",
                                        label: qsTr("Binds")
                                    },
                                    {
                                        icon: "shutter_speed",
                                        label: qsTr("Render")
                                    },
                                    {
                                        icon: "select",
                                        label: qsTr("Cursor")
                                    },
                                    {
                                        icon: "code",
                                        label: qsTr("Debug")
                                    },
                                    {
                                        icon: "data_object",
                                        label: qsTr("Advanced")
                                    },
                                    {
                                        icon: "rule",
                                        label: qsTr("Window Rules")
                                    },
                                    {
                                        icon: "layers",
                                        label: qsTr("Layer Rules")
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
                        readonly property string currentHyprlandCategory: (hyprlandCategoryOffset >= 0 && hyprlandCategoryOffset < hyprlandCategories.length) ? hyprlandCategories[hyprlandCategoryOffset] : ""
                        readonly property var    hyprlandCategories: ["general", "decoration", "input", "group", "misc", "binds", "render", "cursor", "debug", "advanced"]
                        readonly property int    hyprlandCategoryOffset: settingsLoader.currentPage - 22

                        function                 revealCard(cardTitle: string) {
                            const kids = pagesColumn.children;

                            for (let i = 0; i < kids.length; i++) {
                                if (!(kids[i] instanceof Loader) || !kids[i].visible || !kids[i].item || !kids[i].item.revealCard)
                                    continue;

                                kids[i].item.revealCard(cardTitle);
                                return;
                            }
                        }

                        anchors.fill: parent

                        SettingsSearchField {
                            id: settingsSearchField

                            Layout.alignment: Qt.AlignVCenter
                            Layout.fillWidth: true
                            z: 2
                            onActivated: (page, card) => {
                                settingsLoader.currentPage = page;
                                Qt.callLater(() => pagesColumn.revealCard(card));
                            }
                        }

                        PageLoader {
                            pageIndex: 0
                            sourceComponent: GeneralPage {}
                        }

                        PageLoader {
                            pageIndex: 1
                            sourceComponent: LanguagePage {}
                        }

                        PageLoader {
                            pageIndex: 2
                            sourceComponent: AppearancePage {}
                        }

                        PageLoader {
                            pageIndex: 3
                            sourceComponent: WallpaperPage {}
                        }

                        PageLoader {
                            pageIndex: 4
                            sourceComponent: BarPage {}
                        }

                        PageLoader {
                            pageIndex: 5
                            sourceComponent: MediaPlayerPage {}
                        }

                        PageLoader {
                            pageIndex: 6
                            sourceComponent: WeatherPage {}
                        }

                        PageLoader {
                            pageIndex: 7
                            sourceComponent: NotificationPage {}
                        }

                        PageLoader {
                            pageIndex: 8
                            sourceComponent: ClipboardPage {}
                        }

                        PageLoader {
                            pageIndex: 9
                            sourceComponent: CaptureScreenVideoPage {}
                        }

                        PageLoader {
                            pageIndex: 10
                            sourceComponent: VolumePage {}
                        }

                        PageLoader {
                            pageIndex: 11
                            sourceComponent: PrivacyNodesPage {}
                        }

                        PageLoader {
                            pageIndex: 12
                            sourceComponent: DockPage {}
                        }

                        PageLoader {
                            pageIndex: 13
                            sourceComponent: TemplatesPage {}
                        }

                        PageLoader {
                            pageIndex: 14
                            sourceComponent: InternetPage {}
                        }

                        PageLoader {
                            pageIndex: 15
                            sourceComponent: BluetoothPage {}
                        }

                        PageLoader {
                            pageIndex: 16
                            sourceComponent: KDEConnectPage {}
                        }

                        PageLoader {
                            pageIndex: 17
                            sourceComponent: GreeterPage {}
                        }

                        PageLoader {
                            pageIndex: 18
                            sourceComponent: IdlePage {}
                        }

                        PageLoader {
                            pageIndex: 19
                            sourceComponent: LockscreenPage {}
                        }

                        PageLoader {
                            pageIndex: 20
                            sourceComponent: AboutPage {}
                        }

                        PageLoader {
                            pageIndex: 21
                            sourceComponent: MonitorsPage {}
                        }

                        Loader {
                            id: hyprlandOptionsLoader

                            readonly property bool isCurrentPage: settingsLoader.currentPage >= 22 && settingsLoader.currentPage <= 31

                            property string        activeCategory: "general"
                            property bool          keepAlive: false

                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            active: isCurrentPage || keepAlive
                            visible: isCurrentPage
                            onIsCurrentPageChanged: {
                                if (isCurrentPage) {
                                    keepAlive      = true;
                                    activeCategory = pagesColumn.currentHyprlandCategory;
                                }
                            }

                            Connections {

                                function onCurrentPageChanged() {
                                    if (hyprlandOptionsLoader.isCurrentPage)
                                        hyprlandOptionsLoader.activeCategory = pagesColumn.currentHyprlandCategory;
                                }

                                target: settingsLoader
                            }

                            Timer {
                                interval: 60000
                                running: hyprlandOptionsLoader.keepAlive && !hyprlandOptionsLoader.isCurrentPage
                                onTriggered: hyprlandOptionsLoader.keepAlive = false
                            }

                            sourceComponent: HyprlandOptionsPage {
                                category: hyprlandOptionsLoader.activeCategory
                            }
                        }

                        PageLoader {
                            pageIndex: 32
                            sourceComponent: WindowRulesPage {}
                        }

                        PageLoader {
                            pageIndex: 33
                            sourceComponent: LayerRulesPage {}
                        }
                    }
                }
            }
        }
    }
    component PageLoader: Loader {
        id: pageLoader

        required property int  pageIndex

        readonly property bool isCurrentPage: settingsLoader.currentPage === pageIndex

        property bool          keepAlive: false

        Layout.fillHeight: true
        Layout.fillWidth: true
        active: isCurrentPage || keepAlive
        visible: isCurrentPage
        onIsCurrentPageChanged: {
            if (isCurrentPage)
                keepAlive = true;
        }

        Timer {
            interval: 60000
            running: pageLoader.keepAlive && !pageLoader.isCurrentPage
            onTriggered: pageLoader.keepAlive = false
        }
    }
}
