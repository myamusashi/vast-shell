import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.Configs
import qs.Services
import qs.Components
import qs.Components.FileDialog
import "../Components"

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    Flickable {
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentColumn.implicitHeight + (Appearance.margin.large * 2)
        clip: true
        ScrollBar.vertical: ScrollBar {}

        ColumnLayout {
            id: contentColumn
            width: parent.width - (Appearance.margin.large * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.margin.large
            spacing: Appearance.spacing.large

            StyledText {
                text: qsTr("Appearance & Theming")
                font.pixelSize: Appearance.fonts.size.extraLarge
                font.bold: true
                color: Colours.m3Colors.m3OnSurface
                Layout.bottomMargin: Appearance.margin.normal
            }

            SettingsCard {
                title: qsTr("Color System")

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Dark Mode:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }

                    StyledSwitch {
                        checked: Configs.colors.isDarkMode
                        onCheckedChanged: Configs.colors.isDarkMode = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Use Static Colors:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSwitch {
                        checked: Configs.colors.useStaticColors
                        onCheckedChanged: Configs.colors.useStaticColors = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Static Colors Path:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        id: staticColorField

                        text: Configs.colors.staticColorsPath
                        onTextChanged: Configs.colors.staticColorsPath = text
                        Layout.preferredWidth: 300

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                staticColorField.forceActiveFocus();
                                fileDialog.visible = true;
                            }
                        }
                    }

                    FileDialog {
                        id: fileDialog

                        nameFilters: ["*.json"]
                        showHidden: true
                        onFileSelected: path => Configs.colors.staticColorsPath = path
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Use Matugen Colors:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSwitch {
                        checked: Configs.colors.useMatugenColor
                        onCheckedChanged: Configs.colors.useMatugenColor = checked
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Matugen Path (Light):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        text: Configs.colors.matugenConfigPathForLightColor
                        onTextChanged: Configs.colors.matugenConfigPathForLightColor = text
                        Layout.preferredWidth: 300
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Matugen Path (Dark):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        text: Configs.colors.matugenConfigPathForDarkColor
                        onTextChanged: Configs.colors.matugenConfigPathForDarkColor = text
                        Layout.preferredWidth: 300
                    }
                }
            }

            SettingsCard {
                title: qsTr("Typography System")

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Sans Serif Font:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        text: Appearance.fonts.family.sans
                        onTextChanged: Appearance.fonts.family.sans = text
                        Layout.preferredWidth: 250
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Monospace Font:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        text: Appearance.fonts.family.mono
                        onTextChanged: Appearance.fonts.family.mono = text
                        Layout.preferredWidth: 250
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Material Icon Font:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledTextField {
                        text: Appearance.fonts.family.material
                        onTextChanged: Appearance.fonts.family.material = text
                        Layout.preferredWidth: 250
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Font Size Scale:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 1
                        to: 5
                        stepSize: 1
                        value: Appearance.fonts.size.scale
                        onValueChanged: Appearance.fonts.size.scale = value
                        Layout.preferredWidth: 200
                    }
                }
            }

            SettingsCard {
                title: qsTr("Shapes & Layout")

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("UI Corner Roundness (Normal):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 0
                        to: 50
                        stepSize: 1
                        value: Appearance.rounding.normal
                        onValueChanged: Appearance.rounding.normal = value
                        Layout.preferredWidth: 200
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Element Spacing (Normal):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 0
                        to: 50
                        stepSize: 1
                        value: Appearance.spacing.normal
                        onValueChanged: Appearance.spacing.normal = value
                        Layout.preferredWidth: 200
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Padding (Normal):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 0
                        to: 50
                        stepSize: 1
                        value: Appearance.padding.normal
                        onValueChanged: Appearance.padding.normal = value
                        Layout.preferredWidth: 200
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Margin (Normal):")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 0
                        to: 50
                        stepSize: 1
                        value: Appearance.margin.normal
                        onValueChanged: Appearance.margin.normal = value
                        Layout.preferredWidth: 200
                    }
                }
            }

            // Motion & Animation
            SettingsCard {
                title: qsTr("Motion & Animation")

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: qsTr("Animation Durations Scale:")
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.fonts.size.large
                        color: Colours.m3Colors.m3OnSurfaceVariant
                    }
                    StyledSlide {
                        from: 1
                        to: 5
                        stepSize: 1
                        value: Configs.appearance.animations.durations.scale
                        onValueChanged: Configs.appearance.animations.durations.scale = value
                        Layout.preferredWidth: 200
                    }
                }
            }

            Item {
                Layout.fillHeight: true
                implicitHeight: Appearance.margin.large
            }
        }
    }
}
