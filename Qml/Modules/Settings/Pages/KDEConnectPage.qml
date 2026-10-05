pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base
import qs.Components.Dialog.FileDialog
import qs.Services

import "../Components"

SettingsPageBase {
    id: page

    property string deviceIdToTransfer: ""

    pageTitle: qsTr("KDE Connect")

    SettingsCard {
        title: qsTr("Device Discovery")

        SettingRow {
            description: qsTr("Periodically poll for KDE Connect devices on the network.")
            label: qsTr("Enable Polling:")

            StyledSwitch {
                checked: Configs.kdeConnect.pollingEnabled

                onCheckedChanged: Configs.kdeConnect.pollingEnabled = checked
            }
        }
        SettingRow {
            description: qsTr("How often to scan for devices, in seconds.")
            label: qsTr("Poll Interval (s):")

            StyledTextInput {
                Layout.preferredWidth: 120
                text: (Configs.kdeConnect.pollInterval / 1000).toString()
                toggleButtonVisible: false

                onTextChanged: {
                    var parsed = parseInt(text);
                    if (!isNaN(parsed) && parsed > 0)
                        Configs.kdeConnect.pollInterval = parsed * 1000;
                }
            }
        }
    }
    SettingsCard {
        title: qsTr("Local Device")

        SettingRow {
            description: qsTr("Unique identifier of this device.")
            label: qsTr("Device ID:")

            StyledText {
                Layout.maximumWidth: 300
                color: Colours.m3Colors.m3OnSurfaceVariant
                elide: Text.ElideMiddle
                font.pixelSize: Appearance.fonts.size.normal
                text: KDEConnect.myDeviceId || qsTr("Not detected")
            }
        }
    }
    SettingsCard {
        title: qsTr("Paired Devices")

        ColumnLayout {
            spacing: Appearance.spacing.normal

            Loader {
                Layout.alignment: Qt.AlignHCenter
                active: KDEConnect.allDevices.length === 0

                sourceComponent: StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    text: qsTr("No devices paired")
                }
            }
            Repeater {
                model: KDEConnect.allDevices

                delegate: KdeDeviceRow {
                    required property var modelData

                    actionText: qsTr("Transfer")
                    device: modelData

                    onActionTriggered: {
                        page.deviceIdToTransfer = modelData.id;
                        transferFileDialog.openFileDialog();
                    }
                }
            }
        }
    }
    SettingsCard {
        title: qsTr("Available Devices")

        ColumnLayout {
            spacing: Appearance.spacing.normal

            Loader {
                Layout.alignment: Qt.AlignHCenter
                active: KDEConnect.availableDevices.length === 0

                sourceComponent: StyledText {
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    text: qsTr("No devices available")
                }
            }
            Repeater {
                model: KDEConnect.availableDevices

                delegate: KdeDeviceRow {
                    required property var modelData

                    actionText: qsTr("Pair")
                    device: modelData

                    onActionTriggered: KDEConnect.pair(modelData.id)
                }
            }
        }
    }
    FileDialog {
        id: transferFileDialog

        selectFolder: false

        onFileSelected: path => {
            if (page.deviceIdToTransfer)
                KDEConnect.shareFile(page.deviceIdToTransfer, path.replace("file://", ""));
        }
    }
}
