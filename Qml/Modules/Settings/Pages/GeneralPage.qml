pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Components.Button

import qs.Core.Configs
import qs.Services
import qs.Components.Base

import "../Components"

SettingsPageBase {
    function cleanExec(exec) {
        return exec.replace(/%[uUfFdDnNickvm]/g, "").replace(/--\S+/g, "").replace(/--/g, "").trim();
    }

    pageTitle: qsTr("General Settings")

    SettingsCard {
        title: qsTr("Window & Focus")

        SettingRow {
            description: qsTr("Automatically switch the active drawers to the monitor where cursor in.")
            label: qsTr("Follow Focus Monitor:")

            StyledSwitch {
                checked: Configs.generals.followFocusMonitor

                onCheckedChanged: Configs.generals.followFocusMonitor = checked
            }
        }
        SettingRow {
            description: qsTr("Display public holidays inside the calendar widget (NOTE: not every country).")
            label: qsTr("Show Holidays in Calendar:")

            StyledSwitch {
                checked: Configs.generals.showHolidays

                onCheckedChanged: Configs.generals.showHolidays = checked
            }
        }
        SettingRow {
            description: qsTr("Draw an outer border around shell.")
            label: qsTr("Enable Outer Border:")

            StyledSwitch {
                checked: Configs.generals.enableOuterBorder

                onCheckedChanged: Configs.generals.enableOuterBorder = checked
            }
        }
        GridLayout {
            columns: 2

            // transparency sections
            SettingRow {
                description: qsTr("Enable translucent shell.")
                label: qsTr("Enable Transparent Mode:")

                StyledSwitch {
                    checked: Configs.generals.transparent

                    onCheckedChanged: Configs.generals.transparent = checked
                }
            }
            SettingRow {
                description: qsTr("Lower is more transparent.")
                label: qsTr("Transparency Alpha:")

                StyledSlide {
                    Layout.preferredWidth: 200
                    emptyRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3SurfaceContainerHighest;
                    }
                    emptyRectOpacity: {
                        if (!enabled)
                            return 0.12;
                        else
                            return 1.0;
                    }
                    enabled: Configs.generals.transparent
                    filledRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    filledRectOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    from: 0.1
                    handleColor: {
                        if (!enabled)
                            Colours.m3Colors.m3InverseOnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    handleOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    popupDecimals: 1
                    stepSize: 0.1
                    to: 1.0
                    value: Configs.generals.alpha

                    onMoved: Configs.generals.alpha = value
                }
            }
            // transparency sections end

            SettingRow {
                label: qsTr("How much radius blur for album cover:")

                StyledSlide {
                    Layout.preferredWidth: 200
                    from: 1
                    to: 64
                    value: Configs.generals.coverBlurRadius

                    onMoved: Configs.generals.coverBlurRadius = value
                }
            }
            SettingRow {
                description: qsTr("Thickness of the glowing edge indicator when charging detected.")
                label: qsTr("Charging indicator spreads on the screen edge:")

                StyledSlide {
                    Layout.preferredWidth: 200
                    from: 1
                    to: 64
                    value: Configs.generals.chargingGlowSpread

                    onMoved: Configs.generals.chargingGlowSpread = value
                }
            }
        }
    }
    SettingsCard {
        title: qsTr("Default Applications")

        GridLayout {
            columns: 2

            AppSettingRow {
                categories: ["TerminalEmulator"]
                configValue: Configs.generals.apps.terminal
                description: qsTr("Default terminal emulator for opening shell commands.")
                label: qsTr("Terminal:")

                onConfigChanged: value => Configs.generals.apps.terminal = value
            }
            AppSettingRow {
                categories: ["FileManager"]
                configValue: Configs.generals.apps.fileExplorer
                description: qsTr("Default file manager for opening folders.")
                label: qsTr("File Explorer:")

                onConfigChanged: value => Configs.generals.apps.fileExplorer = value
            }
            AppSettingRow {
                categories: ["Viewer"]
                configValue: Configs.generals.apps.imageViewer
                description: qsTr("Default app for viewing images.")
                label: qsTr("Image Viewer:")

                onConfigChanged: value => Configs.generals.apps.imageViewer = value
            }
            AppSettingRow {
                categories: ["Video"]
                configValue: Configs.generals.apps.videoViewer
                description: qsTr("Default app for playing videos.")
                label: qsTr("Video Viewer:")

                onConfigChanged: value => Configs.generals.apps.videoViewer = value
            }
            AppSettingRow {
                categories: ["AudioVideo", "Settings"]
                configValue: Configs.generals.apps.audio
                description: qsTr("Default app for audio and sound configuration.")
                label: qsTr("Audio Settings:")

                onConfigChanged: value => Configs.generals.apps.audio = value
            }
        }
    }

    component AppSettingRow: SettingRow {
        id: appSettingRow

        property var categories: []
        property string configValue

        signal configChanged(string value)

        onConfigValueChanged: appCombo.currentIndex = appModel.values.findIndex(item => item.display === configValue)

        SplitButton {
            id: appCombo

            currentIndex: appModel.values.findIndex(item => item.display === appSettingRow.configValue)
            icon.name: appSettingRow.categories.reduce((acc, item) => {
                switch (item) {
                case "TerminalEmulator":
                    return "terminal";
                case "FileManager":
                    return "folder_open";
                case "Viewer":
                    return "imagesmode";
                case "Video":
                    return "video_file";
                case "AudioVideo":
                    return "audio_file";
                default:
                    return acc;
                }
            }, "apps")
            text: appModel.values[currentIndex]?.display ?? appSettingRow.configValue
            textRole: "display"

            model: ScriptModel {
                id: appModel

                values: {
                    const apps = [...DesktopEntries.applications.values];
                    const filtered = apps.filter(e => appSettingRow.categories.every(c => e.categories.includes(c)));
                    const mapped = filtered.map(e => ({
                                e,
                                display: e.execString.replace(/%[uUfFdDnNickvm]/g, "").replace(/--\S+/g, "").replace(/--/g, "").trim()
                            }));
                    return [...new Map(mapped.map(e => [e.display, e])).values()];
                }
            }

            onMenuItemActivated: index => appSettingRow.configChanged(appModel.values[index].display)
        }
    }
}
