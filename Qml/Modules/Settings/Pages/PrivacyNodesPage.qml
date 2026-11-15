pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Button
import qs.Components.Base
import qs.Core.Configs
import qs.Services

import "../Components"

SettingsPageBase {
    id: root

    property ListModel privacyBlockListModel: ListModel {}

    function           addEntry() {
        privacyBlockListModel.append({
            key: "",
            value: ""
        });
    }

    function           flushToConfig() {
        const obj = {};
        for (let i = 0; i < privacyBlockListModel.count; i++) {
            const e = privacyBlockListModel.get(i);
            if (e.key === "")
                continue;
            obj[e.key] = e.value;
        }
        Configs.privacy.blockPrivacyListNodesName = obj;
    }

    function           removeEntry(i) {
        privacyBlockListModel.remove(i);
        flushToConfig();
    }

    function           seedFromConfig() {
        privacyBlockListModel.clear();
        const map = Configs.privacy.blockPrivacyListNodesName;
        for (const k of Object.keys(map)) {
            privacyBlockListModel.append({
                key: k,
                value: String(map[k])
            });
        }
    }

    pageTitle: qsTr("Pipewire Privacy Nodes")
    Component.onCompleted: seedFromConfig()

    SettingsCard {
        title: qsTr("Privacy nodes")

        SettingRow {
            description: qsTr("Show a privacy list or names through Dynamic Island")
            label: qsTr("Enable privacy indicator")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.privacy.enablePrivacyIndicator
                onToggled: Configs.privacy.enablePrivacyIndicator = checked
            }
        }

        SettingRow {
            description: qsTr("Detect privacy indicator state through Dynamic Island")
            label: qsTr("Privacy indicator in Dynamic Island")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
                checked: Configs.privacy.enablePrivacyIcon
                onToggled: Configs.privacy.enablePrivacyIcon = checked
            }
        }

        SettingRow {
            description: qsTr("Show an icon for privacy indicator in widgets or Dynamic Island")
            label: qsTr("Show icon for privacy indicator")

            StyledSwitch {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 52
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
            model: root.privacyBlockListModel
            spacing: Appearance.margin.normal
            delegate: ColumnLayout {
                id: rootDelegate

                required property int    index
                required property string key
                required property string value

                uniformCellSizes: true
                width: ListView.view.width

                RowLayout {
                    spacing: Appearance.margin.normal

                    MaterialTextField {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        label: qsTr("Name")
                        text: rootDelegate.key
                        onEditingFinished: {
                            root.privacyBlockListModel.setProperty(rootDelegate.index, "key", text);
                            root.flushToConfig();
                        }
                    }

                    MaterialTextField {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        label: qsTr("Value")
                        text: rootDelegate.value
                        onEditingFinished: {
                            root.privacyBlockListModel.setProperty(rootDelegate.index, "value", text);
                            root.flushToConfig();
                        }
                    }
                }

                ExtendedFloatingButton {
                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 240
                    icon.color: Colours.m3Colors.m3Surface
                    icon.name: "delete"
                    text: qsTr("Remove title blocked")
                    textColor: Colours.m3Colors.m3Surface
                    onClicked: root.removeEntry(rootDelegate.index)
                }
            }
        }
    }

    footer: [
        Item {
            Layout.fillWidth: true
        },
        ExtendedFloatingButton {
            outlined: true
            text: qsTr("Add title blocked")
            textColor: Colours.m3Colors.m3OnSurface
            onClicked: {
                root.addEntry();
                root.revealItem(listView, listView.count - 1);
            }
        }
    ]
}
