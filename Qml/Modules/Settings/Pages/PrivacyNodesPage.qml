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

    pageTitle: qsTr("Pipewire Privacy Nodes")

    property ListModel privacyBlockListModel: ListModel {}

    function seedFromConfig() {
        privacyBlockListModel.clear();
        const map = Configs.privacy.blockPrivacyListNodesName;
        for (const k of Object.keys(map)) {
            privacyBlockListModel.append({
                key: k,
                value: String(map[k])
            });
        }
    }

    function flushToConfig() {
        const obj = {};
        for (let i = 0; i < privacyBlockListModel.count; i++) {
            const e = privacyBlockListModel.get(i);
            if (e.key === "")
                continue;
            obj[e.key] = e.value;
        }
        Configs.privacy.blockPrivacyListNodesName = obj;
    }

    function addEntry() {
        privacyBlockListModel.append({
            key: "",
            value: ""
        });
    }

    function removeEntry(i) {
        privacyBlockListModel.remove(i);
        flushToConfig();
    }

    Component.onCompleted: seedFromConfig()

    SettingsCard {
        title: qsTr("Privacy nodes")

        SettingRow {
            label: qsTr("Enable privacy indicator")
            description: qsTr("Show a privacy list or names through Dynamic Island")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.privacy.enablePrivacyIndicator
                onToggled: Configs.privacy.enablePrivacyIndicator = checked
            }
        }

        SettingRow {
            label: qsTr("Privacy indicator in Dynamic Island")
            description: qsTr("Detect privacy indicator state through Dynamic Island")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.privacy.enablePrivacyIcon
                onToggled: Configs.privacy.enablePrivacyIcon = checked
            }
        }

        SettingRow {
            label: qsTr("Show icon for privacy indicator")
            description: qsTr("Show an icon for privacy indicator in widgets or Dynamic Island")

            StyledSwitch {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 32
                checked: Configs.privacy.enablePrivacyIcon
                onToggled: Configs.privacy.enablePrivacyIcon = checked
            }
        }
    }

    SettingsCard {
        title: qsTr("Privacy nodes block title")

        ListView {
            id: listView

            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: Appearance.margin.normal
            model: root.privacyBlockListModel

            delegate: ColumnLayout {
                id: rootDelegate

                required property int index
                required property string key
                required property string value

                width: ListView.view.width
                uniformCellSizes: true

                RowLayout {
                    spacing: Appearance.margin.normal

                    LabeledTextField {
                        label: qsTr("Name:")
                        text: rootDelegate.key
                        onEdited: newText => {
                            root.privacyBlockListModel.setProperty(rootDelegate.index, "key", newText);
                            root.flushToConfig();
                        }
                    }

                    LabeledTextField {
                        label: qsTr("Value:")
                        text: rootDelegate.value
                        onEdited: newText => {
                            root.privacyBlockListModel.setProperty(rootDelegate.index, "value", newText);
                            root.flushToConfig();
                        }
                    }
                }

                ExtendedFloatingButton {
                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                    Layout.preferredWidth: 240
                    Layout.preferredHeight: 40
                    text: qsTr("Remove title blocked")
                    textColor: Colours.m3Colors.m3Surface
                    icon.name: "delete"
                    icon.color: Colours.m3Colors.m3Surface
                    onClicked: root.removeEntry()
                }
            }
        }
    }

    ExtendedFloatingButton {
        text: qsTr("Add title blocked")
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        outlined: true
        textColor: Colours.m3Colors.m3OnSurface
        onClicked: root.addEntry()
    }

    component LabeledTextField: ColumnLayout {
        id: field

        required property string label
        required property string text

        signal edited(string text)

        Layout.fillWidth: true
        Layout.preferredWidth: 0

        StyledText {
            text: field.label
            font.pixelSize: Appearance.fonts.size.normal
            color: Colours.m3Colors.m3OnSurfaceVariant
        }

        TextField {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            text: field.text
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            padding: Appearance.margin.normal
            clip: true

            background: Rectangle {
                radius: Appearance.rounding.small
                color: Colours.m3Colors.m3SurfaceVariant
                opacity: 0.4
            }

            onEditingFinished: field.edited(text)
        }
    }
}
