pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Bluetooth" as BT

import qs.Core.Configs
import qs.Components.Popup

ZoomPopup {
    id: root

    contentMargin: Appearance.margin.normal
    clipContent: true
    enableScroll: false
    content: ColumnLayout {
        width: root.width
        spacing: Appearance.spacing.small

        BT.Header {}

        BT.AdapterControls {
            isVisible: root.isVisible
        }

        ScrollView {
            id: deviceScroll

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(deviceColumn.implicitHeight, 320)
            clip: true
            contentWidth: availableWidth

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ColumnLayout {
                id: deviceColumn

                width: deviceScroll.availableWidth
                spacing: Appearance.spacing.small

                BT.PairedDevices {
                    Layout.fillWidth: true
                }

                BT.AvailableDevices {
                    Layout.fillWidth: true
                }

                BT.BlockedDevices {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
