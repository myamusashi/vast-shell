pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "Wifi" as WF

import qs.Core.Configs
import qs.Components.Dialog
import qs.Components.Popup

ZoomPopup {
    id: root

    contentMargin: Appearance.margin.normal
    clipContent: true
    enableScroll: false
    content: ColumnLayout {
        width: root.width
        spacing: Appearance.spacing.small

        WF.Header {}

        WF.WifiToggle {
            isVisible: root.isVisible
        }

        WF.NetworkList {
            pskDialog: wifiPskDialog
        }
    }

    WifiPskDialog {
        id: wifiPskDialog
    }
}
