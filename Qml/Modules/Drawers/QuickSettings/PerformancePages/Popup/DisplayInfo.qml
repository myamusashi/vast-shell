pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services
import qs.Components.Base

PopupWidget {
    id: root

    readonly property var monitorModel: {
        let model = [];
        for (let name in Hypr.monitorData) {
            let monitor = Hypr.monitorData[name];
            model.push({
                header: qsTr("Monitor"),
                text: qsTr("Description"),
                value: monitor.description
            });
            model.push({
                header: "",
                text: qsTr("Resolution"),
                value: monitor.resolution
            });
            model.push({
                header: "",
                text: qsTr("Scale"),
                value: monitor.scale
            });
            model.push({
                header: "",
                text: qsTr("Refresh Rate"),
                value: monitor.refreshRate + " Hz"
            });
            model.push({
                header: "",
                text: qsTr("Color Management"),
                value: monitor.colorManagementPreset
            });
        }
        return model;
    }

    icon: "computer"
    text: qsTr("Display")

    content: ColumnLayout {
        spacing: Appearance.spacing.normal

        Repeater {
            model: root.monitorModel.concat([
                {
                    text: qsTr("GPU")
                },
                {
                    header: "",
                    text: qsTr("Vulkan"),
                    value: SystemUsage.vulkanAvailable ? SystemUsage.vulkanVersion : qsTr("Not available")
                },
                {
                    header: "",
                    text: qsTr("OpenGL"),
                    value: SystemUsage.openglAvailable ? SystemUsage.openglVersion : qsTr("Not available")
                },
                {
                    header: "",
                    text: qsTr("vaAPI Driver"),
                    value: SystemUsage.vaApiDriver
                },
                {
                    header: "",
                    text: qsTr("OpenGL Renderer"),
                    value: SystemUsage.openglRenderer
                },
                {
                    header: "",
                    text: qsTr("OpenGL Vendor"),
                    value: SystemUsage.openglVendor
                }
            ])

            delegate: ColumnLayout {
                id: delegate

                required property int index
                required property var modelData

                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.topMargin: delegate.modelData.header !== "" ? Appearance.spacing.small : 0
                    color: Colours.m3Colors.m3Green
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    text: delegate.modelData.header
                    visible: delegate.modelData.header !== ""
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small
                    visible: delegate.modelData.text !== ""

                    StyledText {
                        Layout.minimumWidth: 120
                        Layout.preferredWidth: 150
                        color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.7)
                        font.pixelSize: Appearance.fonts.size.normal
                        horizontalAlignment: Text.AlignLeft
                        text: delegate.modelData.text
                    }
                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        text: delegate.modelData.value || qsTr("N/A")
                        wrapMode: Text.Wrap
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                    implicitHeight: 1
                    visible: delegate.modelData.header === "" && delegate.index < root.monitorModel.length + 5
                }
            }
        }
    }
}
