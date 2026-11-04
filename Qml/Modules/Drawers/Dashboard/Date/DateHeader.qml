pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

ColumnLayout {
    id: root

    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
    Layout.fillWidth: true
    spacing: Appearance.spacing.small

    StyledText {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3OnBackground
        font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
        text: Qt.formatDateTime(Time.date, "h:mm:ss ap")
    }

    StyledText {
        Layout.fillWidth: true
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.large
        font.weight: 700
        text: Qt.formatDate(CelestialProgress.now, "dddd")
    }

    StyledText {
        Layout.fillWidth: true
        color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
        font.pixelSize: Appearance.fonts.size.medium
        text: Qt.formatDate(CelestialProgress.now, "d MMMM yyyy")
    }
}
