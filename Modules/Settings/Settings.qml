import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Services
import qs.Components

import "./Components"
import "./Pages"

FloatingWindow {
    id: settingsWindow

    property int currentPage: 0

    color: "transparent"

    Rectangle {
        id: surfaceContainer
        anchors.fill: parent
        color: Colours.m3Colors.m3Surface
        radius: Configs.appearance.rounding.large
        clip: true

        Elevation {
            anchors.fill: parent
            level: 3
            radius: parent.radius
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Configs.appearance.margin.large
            spacing: Configs.appearance.spacing.large

            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Configs.appearance.spacing.small

                    StyledText {
                        text: qsTr("Settings")
                        Layout.fillWidth: true
                        Layout.margins: Configs.appearance.margin.normal
                        Layout.bottomMargin: Configs.appearance.margin.large
                        font.bold: true
                        font.pixelSize: Configs.appearance.fonts.size.extraLarge
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
                        iconName: "horizontal_split"
                        pageIndex: 2
                    }
                    SidebarItem {
                        text: qsTr("Wallpaper")
                        iconName: "wallpaper"
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

                    GeneralPage {}
                    AppearancePage {}
                    BarPage {}
                    WallpaperPage {}
                    WeatherPage {}
                    LanguagePage {}
                }
            }
        }
    }
}
