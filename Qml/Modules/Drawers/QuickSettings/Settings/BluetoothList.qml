pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "Bluetooth" as BT

import qs.Core.Configs
import qs.Components.Popup

ZoomPopup {
    id: root

    clipContent: true
    contentMargin: Appearance.margin.normal
    enableScroll: false

    content: ColumnLayout {
        spacing: Appearance.spacing.small
        width: root.width

        BT.Header {
        }
        BT.AdapterControls {
            isVisible: root.isVisible
        }
        ScrollView {
            id: deviceScroll

            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(deviceColumn.implicitHeight, 320)
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                id: deviceColumn

                spacing: Appearance.spacing.small
                width: deviceScroll.availableWidth

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
