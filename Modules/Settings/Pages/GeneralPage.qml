pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.Configs
import qs.Components
import qs.Services

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    function cleanExec(exec) {
        return exec.replace(/%[uUfFdDnNickvm]/g, "").replace(/--\S+/g, "").replace(/--/g, "").trim();
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: Appearance.margin.large
        }
        spacing: Appearance.spacing.large

        StyledText {
            text: qsTr("General Settings")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Window & Focus")

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Follow Focus Monitor:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    checked: Configs.generals.followFocusMonitor
                    onCheckedChanged: Configs.generals.followFocusMonitor = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enable Transparent Mode:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    checked: Configs.generals.transparent
                    onCheckedChanged: Configs.generals.transparent = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Transparency Alpha:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSlide {
                    from: 0.1
                    to: 1.0
                    stepSize: 0.1
                    value: Configs.generals.alpha
                    onValueChanged: Configs.generals.alpha = value
                    Layout.preferredWidth: 200
                    filledRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    emptyRectColor: {
                        if (!enabled)
                            Colours.m3Colors.m3OnSurface;
                        else
                            Colours.m3Colors.m3SurfaceContainerHighest;
                    }
                    handleColor: {
                        if (!enabled)
                            Colours.m3Colors.m3InverseOnSurface;
                        else
                            Colours.m3Colors.m3Primary;
                    }
                    filledRectOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    emptyRectOpacity: {
                        if (!enabled)
                            return 0.12;
                        else
                            return 1.0;
                    }
                    handleOpacity: {
                        if (!enabled)
                            return 0.38;
                        else
                            return 1.0;
                    }
                    enabled: Configs.generals.transparent
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Enable Outer Border:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.generals.enableOuterBorder
                    onCheckedChanged: Configs.generals.enableOuterBorder = checked
                }
            }
        }

        SettingsCard {
            title: qsTr("Default Applications")

            AppSettingRow {
                label: qsTr("Terminal:")
                categories: ["TerminalEmulator"]
                configValue: Configs.generals.apps.terminal
                onConfigChanged: value => Configs.generals.apps.terminal = value
            }
            AppSettingRow {
                label: qsTr("File Explorer:")
                categories: ["FileManager"]
                configValue: Configs.generals.apps.fileExplorer
                onConfigChanged: value => Configs.generals.apps.fileExplorer = value
            }
            AppSettingRow {
                label: qsTr("Image Viewer:")
                categories: ["Viewer"]
                configValue: Configs.generals.apps.imageViewer
                onConfigChanged: value => Configs.generals.apps.imageViewer = value
            }
            AppSettingRow {
                label: qsTr("Video Viewer:")
                categories: ["Video"]
                configValue: Configs.generals.apps.videoViewer
                onConfigChanged: value => Configs.generals.apps.videoViewer = value
            }
            AppSettingRow {
                label: qsTr("Audio Settings:")
                categories: ["AudioVideo", "Settings"]
                configValue: Configs.generals.apps.audio
                onConfigChanged: value => Configs.generals.apps.audio = value
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component AppSettingRow: RowLayout {
        id: appSetting

        property string label
        property var categories: []
        property string configValue
        signal configChanged(string value)
        Layout.fillWidth: true

        property var appList: [...DesktopEntries.applications.values].filter(e => appSetting.categories.every(c => e.categories.includes(c))).map(e => ({
                    "display": root.cleanExec(e.execString)
                }))

        StyledText {
            text: appSetting.label
            Layout.fillWidth: true
            font.pixelSize: Appearance.fonts.size.large
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        StyledComboBox {
            id: appCombo

            Layout.preferredWidth: 250
            model: appSetting.appList
            currentIndex: appSetting.appList.findIndex(item => item.display === appSetting.configValue)
            placeholderText: appSetting.configValue
            isItemActive: (md, _) => md.display === appSetting.configValue
            onActivated: index => appSetting.configChanged(appSetting.appList[index].display)

            Connections {
                target: appSetting
                function onConfigValueChanged() {
                    appCombo.currentIndex = appSetting.appList.findIndex(item => item.display === appSetting.configValue);
                }
            }
        }
    }
}
