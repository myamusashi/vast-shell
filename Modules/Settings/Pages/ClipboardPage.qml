import QtQuick
import QtQuick.Layouts

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
            text: qsTr("Clipboard configurations")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("General Settings")

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enable Clipboard:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    checked: Configs.clipboard.enabled
                    onCheckedChanged: Configs.clipboard.enabled = checked
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Enable Image Previews:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSwitch {
                    checked: Configs.clipboard.enablePreview
                    onCheckedChanged: Configs.clipboard.enablePreview = checked
                }
            }
        }

        SettingsCard {
            title: qsTr("Preview Dimensions")
            visible: Configs.clipboard.enablePreview

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Preview Width:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSlide {
                    from: 100
                    to: 1000
                    stepSize: 10
					value: Configs.clipboard.preview.sourceWidth
					onMoved: Configs.clipboard.preview.sourceWidth = value
                    Layout.preferredWidth: 200
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Preview Height:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSlide {
                    from: 100
                    to: 1000
                    stepSize: 10
					value: Configs.clipboard.preview.sourceHeight
					onMoved: Configs.clipboard.preview.sourceHeight = value
                    Layout.preferredWidth: 200
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
