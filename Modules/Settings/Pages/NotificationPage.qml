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
            text: qsTr("Notification configurations")
            font.pixelSize: Appearance.fonts.size.extraLarge
            font.bold: true
            color: Colours.m3Colors.m3OnSurface
            Layout.bottomMargin: Appearance.margin.normal
        }

        SettingsCard {
            title: qsTr("Notification Limits")

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Maximum Notifications:")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSlide {
                    from: 10
                    to: 500
                    stepSize: 10
                    value: Configs.notification.maximumNotification
                    onMoved: Configs.notification.maximumNotification = value
                    Layout.preferredWidth: 200
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: qsTr("Maximum Notification Age (Days):")
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.fonts.size.large
                    color: Colours.m3Colors.m3OnSurfaceVariant
                }

                StyledSlide {
                    from: 1
                    to: 30
                    stepSize: 1
                    value: Configs.notification.maximumNotificationAge / 86400000
                    onMoved: Configs.notification.maximumNotificationAge = value * 86400000
                    Layout.preferredWidth: 200
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
