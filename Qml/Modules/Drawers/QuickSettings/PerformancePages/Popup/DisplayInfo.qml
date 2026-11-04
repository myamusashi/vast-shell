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

    function              rowHeader(rowIndex: int): string {
        if (rowIndex < monitorModel.length)
            return monitorModel[rowIndex].header;
        return "";
    }

    function              rowText(rowIndex: int): string {
        if (rowIndex < monitorModel.length)
            return monitorModel[rowIndex].text;
        switch (rowIndex - monitorModel.length) {
        case 0:
            return qsTr("GPU");
        case 1:
            return qsTr("Vulkan");
        case 2:
            return qsTr("OpenGL");
        case 3:
            return qsTr("vaAPI Driver");
        case 4:
            return qsTr("OpenGL Renderer");
        default:
            return qsTr("OpenGL Vendor");
        }
    }

    function              rowValue(rowIndex: int): string {
        if (rowIndex < monitorModel.length)
            return String(monitorModel[rowIndex].value ?? "");
        switch (rowIndex - monitorModel.length) {
        case 0:
            return "";
        case 1:
            return SystemUsage.vulkanAvailable ? SystemUsage.vulkanVersion : qsTr("Not available");
        case 2:
            return SystemUsage.openglAvailable ? SystemUsage.openglVersion : qsTr("Not available");
        case 3:
            return SystemUsage.vaApiDriver;
        case 4:
            return SystemUsage.openglRenderer;
        default:
            return SystemUsage.openglVendor;
        }
    }

    icon: "computer"
    text: qsTr("Display")
    content: ColumnLayout {
        spacing: Appearance.spacing.normal

        Repeater {
            model: root.monitorModel.length + 6
            delegate: ColumnLayout {
                id: delegate

                required property int    index

                readonly property string headerText: root.rowHeader(index)
                readonly property string labelText: root.rowText(index)
                readonly property string valueText: root.rowValue(index)

                Layout.fillWidth: true
                spacing: Appearance.spacing.small

                StyledText {
                    Layout.topMargin: delegate.headerText !== "" ? Appearance.spacing.small : 0
                    color: Colours.m3Colors.m3Green
                    font.pixelSize: Appearance.fonts.size.large
                    font.weight: Font.DemiBold
                    text: delegate.headerText
                    visible: delegate.headerText !== ""
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small
                    visible: delegate.labelText !== ""

                    StyledText {
                        Layout.minimumWidth: 120
                        Layout.preferredWidth: 150
                        color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.7)
                        font.pixelSize: Appearance.fonts.size.normal
                        horizontalAlignment: Text.AlignLeft
                        text: delegate.labelText
                    }

                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.m3Colors.m3OnSurface
                        elide: Text.ElideRight
                        font.pixelSize: Appearance.fonts.size.normal
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                        text: delegate.valueText || qsTr("N/A")
                        wrapMode: Text.Wrap
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing.small
                    color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.1)
                    implicitHeight: 1
                    visible: delegate.headerText === "" && delegate.index < root.monitorModel.length + 5
                }
            }
        }
    }
}
