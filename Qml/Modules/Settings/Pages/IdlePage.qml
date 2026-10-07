pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    property ListModel timeoutsModel: ListModel {}

    function           addTimeout() {
        timeoutsModel.append({
            timeoutSeconds: 60,
            timeoutCommand: "notify-send 'Idle' 'Timeout reached'",
            resumeCommand: ""
        });
        flushToConfig();
    }
    function           flushToConfig() {
        const arr = [];
        for (let i = 0; i < timeoutsModel.count; i++) {
            const e = timeoutsModel.get(i);
            arr.push({
                timeoutMonitor: e.timeoutSeconds,
                "on-timeout": e.timeoutCommand,
                "on-resume": e.resumeCommand
            });
        }
        Configs.idle.timeouts = arr;
    }
    function           removeTimeout(i) {
        timeoutsModel.remove(i);
        flushToConfig();
    }
    function           seedFromConfig() {
        timeoutsModel.clear();
        for (const e of Configs.idle.timeouts)
            timeoutsModel.append({
                timeoutSeconds: e.timeoutMonitor ?? 60,
                timeoutCommand: e["on-timeout"] ?? "",
                resumeCommand: e["on-resume"] ?? ""
            });
    }

    pageTitle: qsTr("Idle")
    Component.onCompleted: seedFromConfig()

    SettingsCard {
        title: qsTr("Idle Management")

        SettingRow {
            description: qsTr("Enable automatic actions after periods of inactivity.")
            label: qsTr("Enable Idle Detection:")

            StyledSwitch {
                checked: Configs.idle.enabled
                onCheckedChanged: Configs.idle.enabled = checked
            }
        }
    }

    SettingsCard {
        title: qsTr("Timeouts")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            Repeater {
                id: timeoutRepeater

                model: root.timeoutsModel
                delegate: Rectangle {
                    id: rootDelegate

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3SurfaceContainerHighest
                    implicitHeight: content.implicitHeight + Appearance.margin.large * 2
                    radius: Appearance.rounding.normal

                    ColumnLayout {
                        id: content

                        spacing: Appearance.spacing.normal

                        anchors {
                            left: parent.left
                            margins: Appearance.margin.large
                            right: parent.right
                            top: parent.top
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                text: qsTr("Timeout (seconds):")
                            }

                            TextField {
                                id: timeoutField

                                Layout.preferredWidth: 80
                                clip: true
                                color: Colours.m3Colors.m3OnSurface
                                font.bold: true
                                font.pixelSize: Appearance.fonts.size.normal
                                inputMethodHints: Qt.ImhDigitsOnly
                                padding: Appearance.margin.normal
                                text: rootDelegate.modelData.timeoutSeconds
                                background: Rectangle {
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                    radius: Appearance.rounding.small
                                }
                                onEditingFinished: {
                                    let val = parseInt(text, 10);
                                    if (isNaN(val) || val < 1)
                                        val = 5;
                                    text = val;
                                    root.timeoutsModel.setProperty(rootDelegate.index, "timeoutSeconds", val);
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                text: qsTr("Command on Timeout:")
                            }

                            TextField {
                                id: onTimeoutField

                                Layout.fillWidth: true
                                clip: true
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                padding: Appearance.margin.normal
                                text: rootDelegate.modelData.timeoutCommand
                                background: Rectangle {
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                    radius: Appearance.rounding.small
                                }
                                onEditingFinished: root.timeoutsModel.setProperty(rootDelegate.index, "timeoutCommand", text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            StyledText {
                                color: Colours.m3Colors.m3OnSurfaceVariant
                                font.pixelSize: Appearance.fonts.size.normal
                                text: qsTr("Command on Resume:")
                            }

                            TextField {
                                id: onResumeField

                                Layout.fillWidth: true
                                clip: true
                                color: Colours.m3Colors.m3OnSurface
                                font.pixelSize: Appearance.fonts.size.normal
                                padding: Appearance.margin.normal
                                text: rootDelegate.modelData.resumeCommand
                                background: Rectangle {
                                    color: Colours.m3Colors.m3SurfaceVariant
                                    opacity: 0.4
                                    radius: Appearance.rounding.small
                                }
                                onEditingFinished: root.timeoutsModel.setProperty(rootDelegate.index, "resumeCommand", text)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            ExtendedFloatingButton {
                                Layout.preferredHeight: 32
                                text: qsTr("Apply")
                                onClicked: root.flushToConfig()
                            }

                            ExtendedFloatingButton {
                                Layout.preferredHeight: 32
                                text: qsTr("Remove")
                                onClicked: root.removeTimeout(rootDelegate.index)
                            }
                        }
                    }
                }
            }
        }
    }

    ExtendedFloatingButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        outlined: true
        text: qsTr("Add Timeout")
        textColor: Colours.m3Colors.m3OnSurface
        onClicked: root.addTimeout()
    }
}
