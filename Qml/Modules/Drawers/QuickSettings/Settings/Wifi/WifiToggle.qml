pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Components.Base
import qs.Components.Feedback
import qs.Core.Configs
import qs.Core.States
import qs.Services

ColumnLayout {
    id: root

    required property bool isVisible

    spacing: Appearance.spacing.small

    Progress {
        Layout.fillWidth: true
        condition: GlobalStates.isWifiScannerOpen && root.isVisible
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            text: qsTr("Wi-Fi")
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            Layout.preferredHeight: 32
            Layout.preferredWidth: 52
            checked: Networking.wifiEnabled
            onToggled: Qt.callLater(() => {
                Networking.wifiEnabled = checked;
            })
        }
    }
}
