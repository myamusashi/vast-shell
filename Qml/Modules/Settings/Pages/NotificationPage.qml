import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Components.Base

import "../Components"

SettingsPageBase {
    pageTitle: qsTr("Notification configurations")

    SettingsCard {
        title: qsTr("Notification Limits")

        SettingRow {
            description: qsTr("Maximum number of stored notifications to keep.")
            label: qsTr("Maximum Notifications:")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 10
                stepSize: 10
                to: 500
                value: Configs.notification.maximumNotification

                onMoved: Configs.notification.maximumNotification = value
            }
        }
        SettingRow {
            description: qsTr("Auto-remove notifications older than this many days.")
            label: qsTr("Maximum Notification Age (Days):")

            StyledSlide {
                Layout.preferredWidth: 200
                from: 1
                stepSize: 1
                to: 30
                value: Configs.notification.maximumNotificationAge / 86400000

                onMoved: Configs.notification.maximumNotificationAge = value * 86400000
            }
        }
    }
}
