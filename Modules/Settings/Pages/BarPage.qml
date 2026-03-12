import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Core.Configs
import qs.Components.Base
import qs.Services

import "../Components"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Appearance.margin.large
        spacing: Appearance.spacing.large

        StyledText {
            text: qsTr("Top Bar Configuration")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Layout & Behavior")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Always Open Bar:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.bar.alwaysOpenBar
                    onCheckedChanged: Configs.bar.alwaysOpenBar = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Compact Navigation Bar:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSwitch {
                    checked: Configs.bar.compact
                    onCheckedChanged: Configs.bar.compact = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Bar Height:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSlide {
                    from: 20
                    to: 100
                    stepSize: 1
                    value: Configs.bar.barHeight
                    onValueChanged: Configs.bar.barHeight = value
                    Layout.preferredWidth: 200
                }
            }
        }

        SettingsCard {
            title: qsTr("Workspace Display")

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Workspace Indicator Style:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                    ToolTip.text: "Available values: 'dot', 'interactive'"
                }
                StyledComboBox {
                    model: [
                        {
                            display: "dot"
                        },
                        {
                            display: "interactive"
                        }
                    ]
                    Layout.preferredWidth: 200
                    currentIndex: -1
                    placeholderText: Configs.bar.workspacesIndicator
                    isItemActive: (md, _) => md.display === Configs.bar.workspacesIndicator
                    onActivated: index => Configs.bar.workspacesIndicator = model[index].display
                }
            }

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: qsTr("Number of Visible Workspaces:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }
                StyledSlide {
                    from: 1
                    to: 15
                    stepSize: 1
                    snapEnabled: true
                    showValuePopup: true
                    value: Configs.bar.visibleWorkspace
                    onValueChanged: Configs.bar.visibleWorkspace = value
                    Layout.preferredWidth: 200
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
