pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog.FileDialog
import qs.Core.Configs
import qs.Services
import qs.Services.Hyprland

import "../../Components"

Rectangle {
    id: root

    required property string modelData

    readonly property var    availableModes: MonitorServices.liveMonitorFor(modelData)?.lastIpcObject?.availableModes ?? []
    readonly property var    cmValues: ["auto", "srgb", "dcip3", "dp3", "adobe", "wide", "edid", "hdr", "hdredid"]
    readonly property var    entry: item.entry ?? {}
    readonly property var    item: MonitorServices.monitorItemForKey(modelData) ?? ({
            entry: {},
            live: false
        })
    readonly property bool   modified: MonitorServices.pending[modelData] !== undefined
    readonly property var    transformLabels: [qsTr("Normal"), qsTr("90°"), qsTr("180°"), qsTr("270°"), qsTr("Flipped"), qsTr("Flipped 90°"), qsTr("Flipped 180°"), qsTr("Flipped 270°")]

    function                 applyMode(mode: string): void {
        const parsed = MonitorServices.parseModeString(mode);
        if (parsed === null)
            return;
        setField("width", parsed.width);
        setField("height", parsed.height);
        setField("refreshRate", parsed.refreshRate);
    }

    function                 commitFloat(field: string, text: string, min: real, max: real): void {
        const parsed = parseFloat(text);
        if (isNaN(parsed))
            return;
        setField(field, Math.min(Math.max(parsed, min), max));
    }

    function                 currentModeIndex(): int {
        return availableModes.findIndex(mode => {
            const parsed = MonitorServices.parseModeString(mode);
            return parsed !== null && parsed.width === (entry.width ?? -1) && parsed.height === (entry.height ?? -1) && Math.abs(parsed.refreshRate - (entry.refreshRate ?? 0)) < 0.01;
        });
    }

    function                 currentModeText(): string {
        const index = currentModeIndex();
        if (index >= 0)
            return availableModes[index];
        return `${entry.width ?? "?"}x${entry.height ?? "?"}@${entry.refreshRate ?? "?"}`;
    }

    function                 setField(field: string, value: var): void {
        MonitorServices.setField(modelData, field, value);
    }

    Layout.fillWidth: true
    color: Colours.m3Colors.m3SurfaceContainerHighest
    implicitHeight: contentColumn.implicitHeight + Appearance.margin.large * 2
    radius: Appearance.rounding.normal
    component EditorField: StyledTextInput {
        autoFocus: false
        placeholderText: ""
        toggleButtonVisible: false
    }

    ColumnLayout {
        id: contentColumn

        spacing: Appearance.spacing.normal

        anchors {
            left: parent.left
            margins: Appearance.margin.large
            right: parent.right
            top: parent.top
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurface
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    text: (root.entry.model ?? "") !== "" ? root.entry.model : root.modelData
                }

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fonts.size.small
                    text: (root.item.live ? qsTr("connected") : qsTr("not connected")) + (root.entry.lastConnector ? ` · ${root.entry.lastConnector}` : "")
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: 6
                Layout.preferredWidth: 6
                color: Colours.m3Colors.m3Primary
                radius: 3
                visible: root.modified
                ToolTip.visible: modifiedHover.hovered
                ToolTip.text: qsTr("Modified — will be written on Apply")

                HoverHandler {
                    id: modifiedHover
                }
            }

            ExtendedFloatingButton {
                enabled: root.modified
                outlined: true
                text: qsTr("Revert")
                textColor: Colours.m3Colors.m3OnSurface
                onClicked: MonitorServices.revertMonitor(root.modelData)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("Mode:")

            SplitButton {
                id: modeButton

                text: root.currentModeText()
                model: root.availableModes.map(mode => {
                    return {
                        text: mode
                    };
                })
                currentIndex: root.currentModeIndex()
                showScrollBar: true
                visible: root.item.live && root.availableModes.length > 0
                onClicked: modeButton.openMenu()
                onMenuItemActivated: index => root.applyMode(root.availableModes[index])
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurfaceVariant
                text: `${root.entry.width ?? "?"}x${root.entry.height ?? "?"}@${root.entry.refreshRate ?? "?"}`
                visible: !(root.item.live && root.availableModes.length > 0)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("Scale:")

            EditorField {
                id: scaleField

                implicitWidth: 90
                onAccepted: root.commitFloat("scale", text, 0.25, 10)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitFloat("scale", text, 0.25, 10);
                }

                Binding {
                    target: scaleField
                    property: "text"
                    value: String(root.entry.scale ?? 1)
                    when: !scaleField.isFocused
                }
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("Transform:")

            SplitButton {
                id: transformButton

                text: root.transformLabels[root.entry.transform ?? 0] ?? qsTr("Normal")
                model: root.transformLabels.map(label => {
                    return {
                        text: label
                    };
                })
                currentIndex: root.entry.transform ?? 0
                showScrollBar: true
                onClicked: transformButton.openMenu()
                onMenuItemActivated: index => root.setField("transform", index)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("Bit depth:")

            SplitButton {
                id: bitdepthButton

                text: (root.entry.bitdepth ?? 8) === 10 ? qsTr("10-bit") : qsTr("8-bit")
                model: [
                    {
                        text: qsTr("8-bit")
                    },
                    {
                        text: qsTr("10-bit")
                    }
                ]
                currentIndex: (root.entry.bitdepth ?? 8) === 10 ? 1 : 0
                onClicked: bitdepthButton.openMenu()
                onMenuItemActivated: index => root.setField("bitdepth", index === 1 ? 10 : 8)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("Color preset:")

            SplitButton {
                id: cmButton

                text: root.entry.cm ?? "srgb"
                model: root.cmValues.map(value => {
                    return {
                        text: value
                    };
                })
                currentIndex: root.cmValues.indexOf(String(root.entry.cm ?? "srgb"))
                showScrollBar: true
                onClicked: cmButton.openMenu()
                onMenuItemActivated: index => root.setField("cm", root.cmValues[index])
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("SDR brightness:")

            EditorField {
                id: sdrBrightnessField

                implicitWidth: 90
                onAccepted: root.commitFloat("sdrbrightness", text, 0.0, 10.0)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitFloat("sdrbrightness", text, 0.0, 10.0);
                }

                Binding {
                    target: sdrBrightnessField
                    property: "text"
                    value: String(root.entry.sdrbrightness ?? 1.0)
                    when: !sdrBrightnessField.isFocused
                }
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("SDR saturation:")

            EditorField {
                id: sdrSaturationField

                implicitWidth: 90
                onAccepted: root.commitFloat("sdrsaturation", text, 0.0, 10.0)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.commitFloat("sdrsaturation", text, 0.0, 10.0);
                }

                Binding {
                    target: sdrSaturationField
                    property: "text"
                    value: String(root.entry.sdrsaturation ?? 1.0)
                    when: !sdrSaturationField.isFocused
                }
            }
        }

        SettingRow {
            Layout.fillWidth: true
            label: qsTr("ICC profile:")

            EditorField {
                id: iccField

                implicitWidth: 190
                placeholderText: qsTr("None")
                onAccepted: root.setField("icc", text)
                onIsFocusedChanged: {
                    if (!isFocused)
                        root.setField("icc", text);
                }

                Binding {
                    target: iccField
                    property: "text"
                    value: String(root.entry.icc ?? "")
                    when: !iccField.isFocused
                }
            }

            FloatingButton {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32
                backgroundRadius: Appearance.rounding.small
                icon.name: "folder_open"
                icon.size: Appearance.fonts.size.normal
                onClicked: iccFileDialog.openFileDialog()
            }
        }

        SettingRow {
            Layout.fillWidth: true
            description: qsTr("Removes the monitor from the layout on Apply.")
            label: qsTr("Disabled:")

            StyledSwitch {
                checked: root.entry.disabled === true
                onToggled: root.setField("disabled", checked)
            }
        }
    }

    FileDialog {
        id: iccFileDialog

        nameFilters: ["*.icc", "*.icm"]
        onFileSelected: path => root.setField("icc", path)
    }
}
