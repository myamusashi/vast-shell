import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.Configs
import qs.Helpers
import qs.Services
import qs.Components

import "./Components"
import "./Pages"

Scope {
    id: scope

    IpcHandler {
        target: "settings"

        function toggle(): void {
            GlobalStates.isSettingsOpen = !GlobalStates.isSettingsOpen;
        }
    }

    GlobalShortcut {
        name: "settings"
        onPressed: GlobalStates.isSettingsOpen = !GlobalStates.isSettingsOpen
    }

    LazyLoader {
        id: settingsLoader

        activeAsync: GlobalStates.isSettingsOpen
        component: FloatingWindow {
            id: settingsWindow

            property int currentPage: 0

            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Colours.m3Colors.m3Surface
                radius: Appearance.rounding.large
                clip: true

                Elevation {
                    anchors.fill: parent
                    level: 3
                    radius: parent.radius
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.margin.large
                    spacing: Appearance.spacing.large

                    Rectangle {
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        color: "transparent"

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Appearance.spacing.small

                            StyledText {
                                text: qsTr("Settings")
                                Layout.fillWidth: true
                                Layout.margins: Appearance.margin.normal
                                Layout.bottomMargin: Appearance.margin.large
                                font.bold: true
                                font.pixelSize: Appearance.fonts.size.extraLarge
                                color: Colours.m3Colors.m3OnSurface
                            }

                            SidebarItem {
                                text: qsTr("General")
                                iconName: "settings"
                                pageIndex: 0
                            }
                            SidebarItem {
                                text: qsTr("Appearance")
                                iconName: "palette"
                                pageIndex: 1
                            }
                            SidebarItem {
                                text: qsTr("Top Bar")
                                iconName: "table_rows"
                                pageIndex: 2
                            }
                            SidebarItem {
                                text: qsTr("Wallpaper")
                                iconName: "wall_art"
                                pageIndex: 3
                            }
                            SidebarItem {
                                text: qsTr("Weather")
                                iconName: "cloud"
                                pageIndex: 4
                            }
                            SidebarItem {
                                text: qsTr("Language")
                                iconName: "language"
                                pageIndex: 5
                            }
                            SidebarItem {
                                text: qsTr("Network & Internet")
                                iconName: "wifi"
                                pageIndex: 6
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Colours.m3Colors.m3OutlineVariant
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        StackLayout {
                            id: stackLayout

                            anchors.fill: parent
                            currentIndex: settingsWindow.currentPage

                            Loader {
                                active: stackLayout.currentIndex === 0
                                sourceComponent: GeneralPage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 1
                                sourceComponent: AppearancePage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 2
                                sourceComponent: BarPage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 3
                                sourceComponent: WallpaperPage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 4
                                sourceComponent: WeatherPage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 5
                                sourceComponent: LanguagePage {}
                            }
                            Loader {
                                active: stackLayout.currentIndex === 6
                                sourceComponent: InternetPage {}
                            }
                        }
                    }
                }
            }
        }
    }
}
