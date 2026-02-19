import QtQuick
import QtQuick.Layouts

import qs.Configs
import qs.Components
import qs.Services

ColumnLayout {
    id: content

    anchors.fill: parent
    spacing: Appearance.spacing.normal

    readonly property bool isConnected: SystemUsage.statusWiredInterface === "connected"

    BrightnessControls {}
    NetworkInfoColumn {}

    RowLayout {
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignLeft
        spacing: Appearance.spacing.normal

        StyledText {
            font.pixelSize: Appearance.fonts.size.small
            text: content.isConnected ? `${SystemUsage.formatUsage(SystemUsage.totalWiredDownloadUsage)} used today (${SystemUsage.wiredInterface})` : "Not connected"
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            font.pixelSize: Appearance.fonts.size.small
            text: Network.active ? `${SystemUsage.formatUsage(SystemUsage.totalWirelessDownloadUsage)} used today (${Network.active})` : "Not connected"
            color: Colours.m3Colors.m3OnSurface
        }
    }

    MediaPlayer {}

    Notifications {}
}
