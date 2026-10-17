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
    Layout.preferredHeight: childrenRect.height
    spacing: Appearance.spacing.small

    StyledText {
        color: Colours.m3Colors.m3OnBackground
        font.pixelSize: Appearance.fonts.size.extraLarge * 1.5
        text: Qt.formatDateTime(Time?.date, "h:mm:ss ap")
    }

    StyledText {
        color: Colours.m3Colors.m3Primary
        font.weight: 700
        font.pixelSize: Appearance.fonts.size.large
        text: Qt.formatDate(Time?.date, "dddd")
    }

    StyledText {
        color: Qt.alpha(Colours.m3Colors.m3OnSurfaceVariant, 0.6)
        font.pixelSize: Appearance.fonts.size.medium
        text: Qt.formatDate(Time?.date, "d MMMM yyyy")
    }
}
