pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    property string label
    Layout.fillWidth: true

    StyledText {
        Layout.fillWidth: true
        text: root.label
        font.pixelSize: Appearance.fonts.size.large
        color: Colours.m3Colors.m3OnSurfaceVariant
    }
}
