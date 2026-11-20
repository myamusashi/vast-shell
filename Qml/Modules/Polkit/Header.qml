import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.Components.Base
import qs.Components.Tooltip
import qs.Core.Configs
import qs.Services

RowLayout {
    spacing: Appearance.spacing.normal

    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 48
        Layout.preferredWidth: 48
        color: Qt.alpha(Colours.m3Colors.m3Primary, 0.5)
        radius: Appearance.rounding.full

        IconImage {
            anchors.centerIn: parent
            height: 28
            source: PolAgent.agent?.flow?.iconName ? Quickshell.iconPath(PolAgent.agent.flow.iconName) : "" // qmllint disable
            width: 28
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            font.pixelSize: Appearance.fonts.size.larger
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: qsTr("Authentication Is Required")
        }

        StyledText {
            id: messageText

            Layout.fillWidth: true
            color: Colours.m3Colors.m3OnSurface
            elide: Text.ElideRight
            font.pixelSize: Appearance.fonts.size.normal
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            maximumLineCount: 3
            text: PolAgent.agent?.flow?.message || qsTr("<no message>") // qmllint disable
            wrapMode: Text.Wrap

            Tooltip {
                anchorItem: messageText
                enabled: messageText.truncated
                text: messageText.text
            }
        }
    }
}
