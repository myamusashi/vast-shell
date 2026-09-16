pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "Bluetooth" as BT

import qs.Core.Configs
import qs.Components.Popup

ZoomPopup {
    id: root

    contentMargin: Appearance.margin.normal
    clipContent: true
    content: ColumnLayout {
        width: root.width
        spacing: Appearance.spacing.small

        BT.Header {}

        BT.AdapterControls {
            isVisible: root.isVisible
        }

        BT.PairedDevices {}

        BT.AvailableDevices {}

        BT.BlockedDevices {}
    }
}
