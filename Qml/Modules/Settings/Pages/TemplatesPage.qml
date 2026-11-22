pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Components.Dialog.FileDialog
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    property int       browseIndex: -1
    property ListModel templateModel: ListModel {}

    function           addTemplate() {
        templateModel.append({
            name: qsTr("New template"),
            input: "",
            outputPath: "",
            postHook: "",
            templateEnabled: true
        });
        flushToConfig();
    }

    function           configEntries() {
        const entries = [];
        for (let index = 0; index < templateModel.count; index++) {
            const entry = templateModel.get(index);
            entries.push({
                name: entry.name,
                input: entry.input,
                output_path: entry.outputPath,
                post_hook: entry.postHook,
                enabled: entry.templateEnabled
            });
        }
        return entries;
    }

    function           flushToConfig() {
        TemplateConfigs.templates = configEntries();
    }

    function           removeTemplate(index) {
        templateModel.remove(index);
        flushToConfig();
    }

    function           saveField(index, role, value) {
        const entry = templateModel.get(index);
        if (entry[role] === value)
            return;
        templateModel.setProperty(index, role, value);
        flushToConfig();
    }

    function           seedFromConfig() {
        templateModel.clear();
        for (const template of TemplateConfigs.templates ?? []) {
            templateModel.append({
                name: template.name ?? "",
                input: template.input ?? "",
                outputPath: template.output_path ?? "",
                postHook: template.post_hook ?? "",
                templateEnabled: template.enabled !== false
            });
        }
    }

    pageTitle: qsTr("Color Templates")
    Component.onCompleted: seedFromConfig()

    Connections {

        function onTemplatesChanged(): void {
            if (JSON.stringify(root.configEntries()) === JSON.stringify(TemplateConfigs.templates ?? []))
                return;
            root.seedFromConfig();
        }

        target: TemplateConfigs
    }

    SettingsCard {
        Layout.fillWidth: true
        title: qsTr("Templates")

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.large

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Templates are rendered with the palette of the current wallpaper. A template named colors.conf.tmpl or colors.conf.template is rendered into colors.conf next to it.")
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3Error
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("A rendered file replaces the file that is already there. A file you edited by hand is lost when the template is rendered again.")
                wrapMode: Text.WordWrap
            }

            StyledText {
                Layout.fillWidth: true
                color: Colours.m3Colors.m3OnSurfaceVariant
                font.pixelSize: Appearance.fonts.size.small
                text: qsTr("Template list: %1").arg(TemplateConfigs.configPath)
                wrapMode: Text.WordWrap
            }

            Repeater {
                id: templateRepeater

                model: root.templateModel
                delegate: Rectangle {
                    id: templateDelegate

                    required property bool   templateEnabled
                    required property string input
                    required property int    index
                    required property string name
                    required property string outputPath
                    required property string postHook

                    Layout.fillWidth: true
                    color: Colours.m3Colors.m3SurfaceContainerHigh
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

                            MaterialTextField {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                label: qsTr("Name")
                                text: templateDelegate.name
                                onEditingFinished: root.saveField(templateDelegate.index, "name", text)
                            }

                            StyledSwitch {
                                id: templateEnabledSwitch

                                checked: templateDelegate.templateEnabled
                                onCheckedChanged: root.saveField(templateDelegate.index, "templateEnabled", checked)

                                Tooltip {
                                    anchorItem: templateEnabledSwitch
                                    text: templateDelegate.templateEnabled ? qsTr("Disable template") : qsTr("Enable template")
                                }
                            }

                            FloatingButton {
                                implicitHeight: 32
                                implicitWidth: 32
                                icon.name: "delete"
                                tooltipText: qsTr("Delete template")
                                onClicked: root.removeTemplate(templateDelegate.index)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.normal

                            MaterialTextField {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                label: qsTr("Template")
                                placeholderText: qsTr("Path of the template file")
                                text: templateDelegate.input
                                onEditingFinished: root.saveField(templateDelegate.index, "input", text)
                            }

                            FloatingButton {
                                implicitHeight: 32
                                implicitWidth: 32
                                icon.name: "folder_open"
                                tooltipText: qsTr("Browse template file")
                                onClicked: {
                                    root.browseIndex = templateDelegate.index;
                                    templateFileDialog.openFileDialog();
                                }
                            }
                        }

                        MaterialTextField {
                            Layout.fillWidth: true
                            label: qsTr("Output")
                            placeholderText: qsTr("Rendered into: %1").arg(TemplateServices.resolvedOutputPath({
                                input: templateDelegate.input,
                                output_path: templateDelegate.outputPath
                            }))
                            text: templateDelegate.outputPath
                            onEditingFinished: root.saveField(templateDelegate.index, "outputPath", text)
                        }

                        MaterialTextField {
                            Layout.fillWidth: true
                            label: qsTr("Post hook")
                            placeholderText: qsTr("Command that runs after the file is written")
                            text: templateDelegate.postHook
                            onEditingFinished: root.saveField(templateDelegate.index, "postHook", text)
                        }
                    }
                }
            }
        }
    }

    footer: [
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            icon.name: "add"
            text: qsTr("Add Template")
            textColor: Colours.m3Colors.m3OnSurface
            color: Colours.m3Colors.m3SecondaryContainer
            onClicked: {
                root.addTemplate();
                root.revealItem(templateRepeater, templateRepeater.count - 1);
            }
        },
        ExtendedFloatingButton {
            enabled: !TemplateServices.renderRunning
            icon.name: "refresh"
            text: qsTr("Render Now")
            textColor: Colours.m3Colors.m3OnSurface
            color: Colours.m3Colors.m3SecondaryContainer
            onClicked: TemplateServices.render()
        }
    ]

    FileDialog {
        id: templateFileDialog

        nameFilters: ["*.tmpl", "*.template", "*"]
        onFileSelected: path => {
            if (root.browseIndex < 0)
                return;
            root.templateModel.setProperty(root.browseIndex, "input", path);
            root.flushToConfig();
            root.browseIndex = -1;
        }
    }
}
