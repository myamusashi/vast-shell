pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Core.Configs
import qs.Services

RowLayout {
    id: root

    default property alias content: controlContainer.data
    property alias description: description.text
    property alias label: label.text

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
        spacing: 2

        StyledText {
            id: label

            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.large
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap
        }
        StyledText {
            id: description

            Layout.fillWidth: true
            color: Qt.alpha(Colours.m3Colors.m3OnSurface, 0.5)
            font.pixelSize: Appearance.fonts.size.small
            horizontalAlignment: Text.AlignLeft
            visible: text !== ""
            wrapMode: Text.Wrap
        }
    }
    RowLayout {
        id: controlContainer

        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
        spacing: Appearance.spacing.small
    }
}
