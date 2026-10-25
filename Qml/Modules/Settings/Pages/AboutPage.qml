pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    readonly property string commit: root.revision === "unknown" ? root.revision : root.revision.slice(0, 7)
    readonly property var    laptopBattery: UPower.devices.values.find(device => device.ready && device.isLaptopBattery && device.isPresent) ?? null
    readonly property string revision: Quickshell.env("VAST_SHELL_REVISION") || "unknown"
    readonly property string version: Quickshell.env("VAST_SHELL_VERSION") || "0.1.0"

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3Primary
            font.family: Fonts.mono
            font.pixelSize: Appearance.fonts.size.small * 0.5
            lineHeight: 1.0
            text: Distro.ascii(SystemUsage.osId, SystemUsage.osIdLike)
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurface
            font.bold: true
            text: qsTr("Vast Shell (i don't have a icons)")
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("A customizable desktop shell")
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Colours.m3Colors.m3OnSurfaceVariant
            text: qsTr("Version %1").arg(root.version)
        }
    }

    SettingsCard {
        title: qsTr("System Information")

        Repeater {
            model: [
                {
                    label: qsTr("Operating System"),
                    value: SystemUsage.osPrettyName
                },
                {
                    label: qsTr("Kernel"),
                    value: SystemUsage.kernelName
                },
                {
                    label: qsTr("Architecture"),
                    value: SystemUsage.archDesign
                },
                {
                    label: qsTr("Processor"),
                    value: SystemUsage.cpuName
                },
                {
                    label: qsTr("Displays"),
                    value: Quickshell.screens.map(screen => `${screen.name} — ${screen.width}×${screen.height}`).join("\n")
                },
                {
                    label: qsTr("Maintainer"),
                    value: "myamusashi"
                },
                {
                    label: qsTr("Latest update"),
                    value: qsTr("v%1 · commit %2").arg(root.version).arg(root.commit)
                }
            ]
            delegate: RowLayout {
                id: systemInfoRow

                required property var modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.normal

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    font.pixelSize: Appearance.fonts.size.normal
                    text: systemInfoRow.modelData.label
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    font.pixelSize: Appearance.fonts.size.normal
                    horizontalAlignment: Text.AlignRight
                    text: systemInfoRow.modelData.value || qsTr("Unknown")
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("RAM & Storage")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("RAM: %1 / %2").arg(SystemUsage.formatKB(SystemUsage.memUsed)).arg(SystemUsage.formatKB(SystemUsage.memTotal))
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 8
                color: Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: Colours.m3Colors.m3Primary
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * (SystemUsage.memTotal > 0 ? Math.max(0, Math.min(1, SystemUsage.memUsed / SystemUsage.memTotal)) : 0)
                }
            }

            StyledText {
                Layout.topMargin: Appearance.spacing.normal
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.normal
                text: qsTr("Storage: %1 / %2").arg(SystemUsage.formatKB(SystemUsage.diskUsed)).arg(SystemUsage.formatKB(SystemUsage.diskTotal))
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 8
                color: Colours.m3Colors.m3SurfaceContainerHighest
                radius: Appearance.rounding.small

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    color: Colours.m3Colors.m3Primary
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * (SystemUsage.diskTotal > 0 ? Math.max(0, Math.min(1, SystemUsage.diskUsed / SystemUsage.diskTotal)) : 0)
                }
            }
        }
    }

    SettingsCard {
        title: qsTr("Battery")
        visible: root.laptopBattery !== null

        SettingRow {
            label: qsTr("Charge")

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                text: root.laptopBattery ? qsTr("%1% · %2").arg((root.laptopBattery.percentage * 100).toFixed(0)).arg(root.laptopBattery.model || qsTr("Battery")) : ""
            }
        }
    }
}
