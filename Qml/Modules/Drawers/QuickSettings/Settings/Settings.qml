pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import qs.Core.Configs
import qs.Components.Base
import qs.Services

Item {
    id: root
    readonly property bool        anyPopupVisible: wifiPopup.isVisible || ethernetPopup.isVisible || bluetoothPopup.isVisible
    readonly property var         connectedWifiNetwork: wifiDevice?.networks.values.find(network => network.connected) ?? null
    readonly property bool        isConnected: SystemUsage.statusWiredInterface === "connected"
    readonly property string      wifiConnectedName: connectedWifiNetwork?.name ?? ""
    readonly property WifiDevice  wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wiredDevice: SystemUsage.ethernetDevice

    property alias                bluetooth: bluetoothPopup
    property alias                ethernet: ethernetPopup
    property alias                wifi: wifiPopup

    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        enabled: !root.anyPopupVisible
        spacing: Appearance.spacing.normal

        BrightnessControls {}

        NetworkInfoColumn {
            bluetoothOpen: bluetoothPopup.isVisible
            connectedWifiNetwork: root.connectedWifiNetwork
            ethernetOpen: ethernetPopup.isVisible
            wifiDevice: root.wifiDevice
            wifiOpen: wifiPopup.isVisible
            wiredDevice: root.wiredDevice
            onBluetoothClicked: bluetoothPopup.toggle()
            onEthernetClicked: ethernetPopup.toggle()
            onWifiClicked: wifiPopup.toggle()
        }

        RowLayout {
            Layout.alignment: Qt.AlignLeft
            Layout.fillHeight: true
            spacing: Appearance.spacing.normal

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.small
                text: root.isConnected ? `${SystemUsage.formatUsageMiB(SystemUsage.totalWiredDownloadUsage)} used today (${SystemUsage.wiredInterface})` : "Not connected"
            }

            StyledText {
                color: Colours.m3Colors.m3OnSurface
                font.pixelSize: Appearance.fonts.size.small
                text: Networking.wifiEnabled ? `${SystemUsage.formatUsageMiB(SystemUsage.totalWirelessDownloadUsage)} used today (${root.wifiConnectedName})` : "Not connected"
            }
        }

        MediaPlayer {}

        Notifications {
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillHeight: true
            Layout.fillWidth: true
        }
    }

    LazyPopup {
        id: wifiPopup

        sourceComponent: WifiList {
            hostItem: root
            isVisible: wifiPopup.isVisible
            onClosed: wifiPopup.isVisible = false
        }
    }

    LazyPopup {
        id: ethernetPopup

        sourceComponent: EthernetList {
            hostItem: root
            isVisible: ethernetPopup.isVisible
            onClosed: ethernetPopup.isVisible = false
        }
    }

    LazyPopup {
        id: bluetoothPopup

        sourceComponent: BluetoothList {
            hostItem: root
            isVisible: bluetoothPopup.isVisible
            onClosed: bluetoothPopup.isVisible = false
        }
    }

    StyledRect {
        anchors.fill: parent
        color: Qt.alpha(Colours.m3Colors.m3Surface, 0.7)
        visible: root.anyPopupVisible

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => {
                if (wifiPopup.isVisible && (mouse.x < wifiPopup.x || mouse.x > wifiPopup.x + wifiPopup.width || mouse.y < wifiPopup.y || mouse.y > wifiPopup.y + wifiPopup.height))
                    wifiPopup.close();
                if (ethernetPopup.isVisible && (mouse.x < ethernetPopup.x || mouse.x > ethernetPopup.x + ethernetPopup.width || mouse.y < ethernetPopup.y || mouse.y > ethernetPopup.y + ethernetPopup.height))
                    ethernetPopup.close();
                if (bluetoothPopup.isVisible && (mouse.x < bluetoothPopup.x || mouse.x > bluetoothPopup.x + bluetoothPopup.width || mouse.y < bluetoothPopup.y || mouse.y > bluetoothPopup.y + bluetoothPopup.height))
                    bluetoothPopup.close();
            }
        }
    }

    component LazyPopup: Loader {
        property bool isVisible: false

        function      close(): void {
            isVisible = false;
        }

        function      toggle(): void {
            active    = true;
            isVisible = !isVisible;
        }

        active: false
        anchors.centerIn: parent
        asynchronous: false
        z: 99
    }
}
