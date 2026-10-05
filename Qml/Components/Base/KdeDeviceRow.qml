pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.Components.Base
import qs.Components.Button
import qs.Core.Configs
import qs.Core.Utils
import qs.Services

RowLayout {
    id: root

    property bool actionEnabled: true
    property string actionText: ""
    required property var device

    signal actionTriggered

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    Icon {
        color: Colours.m3Colors.m3Primary
        font.pixelSize: Appearance.fonts.size.normal
        icon: "smartphone"
    }
    ColumnLayout {
        spacing: 2

        StyledText {
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            text: root.device?.name ?? ""
        }
        StyledText {
            Layout.maximumWidth: 250
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideMiddle
            font.pixelSize: Appearance.fonts.size.small
            text: root.device?.id ?? ""
        }
    }
    Item {
        Layout.fillWidth: true
    }
    ExtendedFloatingButton {
        color: "transparent"
        enabled: root.actionEnabled
        implicitHeight: 32
        text: root.actionText
        textColor: Colours.m3Colors.m3Primary
        visible: root.actionText !== ""

        onClicked: root.actionTriggered()
    }
}
