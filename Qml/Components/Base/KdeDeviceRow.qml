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

    required property var device
    property string actionText: ""
    property bool actionEnabled: true

    signal actionTriggered

    Layout.fillWidth: true
    spacing: Appearance.spacing.normal

    Icon {
        icon: "smartphone"
        font.pixelSize: Appearance.fonts.size.normal
        color: Colours.m3Colors.m3Primary
    }

    ColumnLayout {
        spacing: 2

        StyledText {
            text: root.device?.name ?? ""
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.DemiBold
            color: Colours.m3Colors.m3OnSurface
        }

        StyledText {
            text: root.device?.id ?? ""
            font.pixelSize: Appearance.fonts.size.small
            color: Colours.m3Colors.m3OnSurfaceVariant
            elide: Text.ElideMiddle
            Layout.maximumWidth: 250
        }
    }

    Item {
        Layout.fillWidth: true
    }

    ExtendedFloatingButton {
        visible: root.actionText !== ""
        enabled: root.actionEnabled
        implicitHeight: 32
        text: root.actionText
        textColor: Colours.m3Colors.m3Primary
        color: "transparent"
        onClicked: root.actionTriggered()
    }
}
