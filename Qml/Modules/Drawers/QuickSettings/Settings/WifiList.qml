pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "Wifi" as WF

import qs.Core.Configs
import qs.Components.Dialog
import qs.Components.Popup

ZoomPopup {
    id: root

    clipContent: true
    contentMargin: Appearance.margin.normal
    enableScroll: false

    content: ColumnLayout {
        spacing: Appearance.spacing.small
        width: root.width

        WF.Header {
        }
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
