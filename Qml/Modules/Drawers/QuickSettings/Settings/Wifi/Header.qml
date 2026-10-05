pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

ColumnLayout {
    Layout.alignment: Qt.AlignCenter
    spacing: Appearance.spacing.small

    StyledText {
        Layout.alignment: Qt.AlignCenter
        color: Colours.m3Colors.m3OnSurface
        font.pixelSize: Appearance.fonts.size.large * 1.5
        font.weight: Font.DemiBold
        text: qsTr("Internet")
    }
    StyledText {
        Layout.alignment: Qt.AlignCenter
        color: Colours.m3Colors.m3OnSurfaceVariant
        font.pixelSize: Appearance.fonts.size.medium
        font.weight: Font.DemiBold
        text: qsTr("Tap/click a network to connect")
    }
}
